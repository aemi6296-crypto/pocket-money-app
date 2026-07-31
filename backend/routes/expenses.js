const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');

router.get('/history/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const sentSnapshot = await db.collection('transactions')
      .where('senderId', '==', userId)
      .get();

    const receivedSnapshot = await db.collection('transactions')
      .where('receiverId', '==', userId)
      .get();

    const sent = sentSnapshot.docs.map(doc => ({ id: doc.id, direction: 'out', ...doc.data() }));
    const received = receivedSnapshot.docs.map(doc => ({ id: doc.id, direction: 'in', ...doc.data() }));

    const allTransactions = [...sent, ...received].sort((a, b) => {
      const timeA = a.createdAt ? a.createdAt.toMillis() : 0;
      const timeB = b.createdAt ? b.createdAt.toMillis() : 0;
      return timeB - timeA; 
    });

    res.status(200).json({
      message: 'Transaction history found ✅',
      transactions: allTransactions
    });

  } catch (error) {
    res.status(500).json({ message: 'Failed to get transaction history ❌', error: error.message });
  }
});


router.get('/summary/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const sentSnapshot = await db.collection('transactions')
      .where('senderId', '==', userId)
      .get();

    const receivedSnapshot = await db.collection('transactions')
      .where('receiverId', '==', userId)
      .get();

    let totalSpent = 0;
    sentSnapshot.docs.forEach(doc => { totalSpent += doc.data().amount; });

    let totalReceived = 0;
    receivedSnapshot.docs.forEach(doc => { totalReceived += doc.data().amount; });

    res.status(200).json({
      message: 'Summary found ✅',
      totalSpent,
      totalReceived
    });

  } catch (error) {
    res.status(500).json({ message: 'Failed to get summary ❌', error: error.message });
  }
});

module.exports = router;
