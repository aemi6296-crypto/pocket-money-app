const express = require('express');
const router = express.Router();
const { admin, db } = require('../config/firebase');


router.get('/weekly/:kidId', async (req, res) => {
  const { kidId } = req.params;

  try {
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

    const receivedSnapshot = await db.collection('transactions')
      .where('receiverId', '==', kidId)
      .where('createdAt', '>=', oneWeekAgo)
      .get();

    const spentSnapshot = await db.collection('transactions')
      .where('senderId', '==', kidId)
      .where('createdAt', '>=', oneWeekAgo)
      .get();

    let totalReceived = 0;
    const receivedBreakdown = {};
    receivedSnapshot.docs.forEach(doc => {
      const data = doc.data();
      totalReceived += data.amount;
      receivedBreakdown[data.type] = (receivedBreakdown[data.type] || 0) + data.amount;
    });

    let totalSpent = 0;
    const spentBreakdown = {};
    spentSnapshot.docs.forEach(doc => {
      const data = doc.data();
      totalSpent += data.amount;
      spentBreakdown[data.type] = (spentBreakdown[data.type] || 0) + data.amount;
    });

    res.status(200).json({
      message: 'Weekly report generated ✅',
      periodStart: oneWeekAgo,
      totalReceived,
      totalSpent,
      receivedBreakdown,
      spentBreakdown
    });

  } catch (error) {
    res.status(500).json({ message: 'Failed to generate report ❌', error: error.message });
  }
});

module.exports = router;
