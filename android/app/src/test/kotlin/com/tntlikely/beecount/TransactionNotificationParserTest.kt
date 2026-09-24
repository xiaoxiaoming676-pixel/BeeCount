package com.tntlikely.beecount

import org.junit.Assert.*
import org.junit.Test

class TransactionNotificationParserTest {
    private val wechat = "com.tencent.mm"
    private val alipay = "com.eg.android.AlipayGphone"

    @Test fun wechatExpense() {
        val event = TransactionNotificationParser.parse(wechat, "微信支付", "付款成功 ¥18.50 向早餐店付款", 1000L)!!
        assertEquals(1850L, event.amountMinor)
        assertEquals("expense", event.type)
        assertEquals("早餐店", event.merchant)
        assertTrue(event.needsReview)
    }

    @Test fun alipayExpense() {
        val event = TransactionNotificationParser.parse(alipay, "支付宝交易提醒", "消费金额 35.00元 商户：便利店", 1000L)!!
        assertEquals("alipay", event.source)
        assertEquals(3500L, event.amountMinor)
        assertEquals("便利店", event.merchant)
    }

    @Test fun refundAndTransferStayDistinct() {
        val refund = TransactionNotificationParser.parse(alipay, "退款到账", "退款¥8.00", 1000L)!!
        val transfer = TransactionNotificationParser.parse(wechat, "微信转账", "转账20元", 2000L)!!
        assertEquals("refund", refund.type)
        assertEquals("transfer", transfer.type)
        assertTrue(transfer.needsReview)
    }

    @Test fun incompleteAmountNeedsReview() {
        val event = TransactionNotificationParser.parse(wechat, "微信支付", "付款成功，金额请查看账单", 1000L)!!
        assertNull(event.amountMinor)
        assertTrue(event.needsReview)
        assertNull(TransactionNotificationParser.parse(wechat, "朋友消息", "早餐35元", 1000L))
        assertNull(TransactionNotificationParser.parse("com.example.other", "支付", "20元", 1000L))
    }

    @Test fun exactUpdatesAndDifferentPayments() {
        val firstId = TransactionNotificationParser.eventId(wechat, "key-1", 1000L, "付款", "20元")
        val again = TransactionNotificationParser.eventId(wechat, "key-1", 1000L, "付款", "20元")
        val secondId = TransactionNotificationParser.eventId(wechat, "key-2", 1300L, "付款", "20元")
        assertEquals(firstId, again)
        assertNotEquals(firstId, secondId)
        val a = TransactionNotificationParser.parse(wechat, "付款", "20元 商户：早餐店", 1000L)!!
        val b = TransactionNotificationParser.parse(wechat, "付款", "20元 商户：咖啡店", 1300L)!!
        val linked = TransactionNotificationParser.parse(alipay, "付款", "20元 商户：早餐店", 1300L)!!
        assertFalse(TransactionNotificationParser.possibleDuplicate(a, b))
        assertTrue(TransactionNotificationParser.possibleDuplicate(a, linked))
    }
}
