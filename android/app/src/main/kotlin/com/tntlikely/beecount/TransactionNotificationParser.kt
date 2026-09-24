package com.tntlikely.beecount

import java.security.MessageDigest

/** Local notification interpretation. Every result still needs user review. */
internal object TransactionNotificationParser {
    private val amountPattern = Regex("[¥￥]\\s*(\\d{1,9}(?:,\\d{3})*(?:\\.\\d{1,2})?)|(\\d{1,9}(?:,\\d{3})*(?:\\.\\d{1,2})?)\\s*元")
    private val merchantPattern = Regex("(?:商户|收款方|交易对象)[:：]\\s*([^，。\\n]{1,40})")
    private val payerPattern = Regex("向([^，。\\n]{1,40}?)付款")
    private val allowedPackages = setOf("com.tencent.mm", "com.eg.android.AlipayGphone")

    data class Candidate(
        val source: String,
        val amountMinor: Long?,
        val type: String,
        val merchant: String?,
        val timestampMillis: Long,
        val needsReview: Boolean = true,
    )

    fun parse(packageName: String, title: String, body: String, postedAtMillis: Long): Candidate? {
        if (packageName !in allowedPackages) return null
        val source = if (packageName == "com.tencent.mm") "wechat" else "alipay"
        val combined = "$title\n$body"
        val amounts = amountPattern.findAll(combined).mapNotNull { match ->
            val raw = (match.groups[1]?.value ?: match.groups[2]?.value)?.replace(",", "")
            runCatching { raw?.toBigDecimal()?.movePointRight(2)?.longValueExact() }
                .getOrNull()?.takeIf { it > 0 }
        }.distinct().toList()
        val type = when {
            Regex("退款|退回|退还").containsMatchIn(combined) -> "refund"
            Regex("转账|转给|提现|充值|还款").containsMatchIn(combined) -> "transfer"
            Regex("付款|支付|消费|支出").containsMatchIn(combined) -> "expense"
            Regex("收款|收入|入账|到账").containsMatchIn(combined) -> "income"
            else -> "unknown"
        }
        // Do not turn unrelated chat or advertising notifications into transactions.
        if (type == "unknown") return null
        val merchant = merchantPattern.find(combined)?.groupValues?.get(1)?.trim()
            ?: payerPattern.find(combined)?.groupValues?.get(1)?.trim()
        return Candidate(source, amounts.singleOrNull(), type, merchant, postedAtMillis)
    }

    /** Exact updates of one notification can be collapsed; distinct same-value payments cannot. */
    fun eventId(packageName: String, notificationKey: String, postedAtMillis: Long,
                title: String, body: String): String {
        val data = "$packageName\u0000$notificationKey\u0000$postedAtMillis\u0000$title\u0000$body"
        return MessageDigest.getInstance("SHA-256").digest(data.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
    }

    /** Possible linked wallet/bank messages need manual matching, never automatic merging. */
    fun possibleDuplicate(a: Candidate, b: Candidate): Boolean =
        a.amountMinor != null && a.amountMinor == b.amountMinor &&
            a.type == b.type && a.merchant != null && a.merchant == b.merchant &&
            kotlin.math.abs(a.timestampMillis - b.timestampMillis) <= 60_000L
}
