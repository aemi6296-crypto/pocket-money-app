const express = require('express');
const router = express.Router();
const { admin, db, sendPushNotification } = require('../config/firebase');


router.post('/send', async (req, res) => {
  const { senderId, receiverId, amount, note } = req.body;

  if (!senderId || !receiverId || !amount) {
    return res.status(400).json({
      message: 'senderId, receiverId and amount are required'
    });
  }

  if (amount <= 0) {
    return res.status(400).json({ message: 'Amount must be greater than 0' });
  }

  try {
    const senderWalletRef = db.collection('wallets').doc(senderId);
    const receiverWalletRef = db.collection('wallets').doc(receiverId);

    await db.runTransaction(async (t) => {
      const senderWallet = await t.get(senderWalletRef);
      const receiverWallet = await t.get(receiverWalletRef);

      if (!senderWallet.exists) throw new Error('Sender wallet not found');
      if (!receiverWallet.exists) throw new Error('Receiver wallet not found');

      const senderBalance = senderWallet.data().balance;
      if (senderBalance < amount) throw new Error('Insufficient balance');

      t.update(senderWalletRef, {
        balance: admin.firestore.FieldValue.increment(-amount)
      });

      t.update(receiverWalletRef, {
        balance: admin.firestore.FieldValue.increment(amount)
      });

      const transactionRef = db.collection('transactions').doc();
      t.set(transactionRef, {
        senderId,
        receiverId,
        amount,
        type: 'transfer',
        description: note || 'Money transfer',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await sendPushNotification(
      receiverId,
      'Money received! 💸',
      `You just received $${amount}`
    );

    res.status(200).json({
      message: 'Transfer successful ✅',
      amount
    });

  } catch (error) {
    if (error.message === 'Insufficient balance') {
      return res.status(400).json({ message: 'Insufficient balance ❌' });
    }
    res.status(500).json({
      message: 'Transfer failed ❌',
      error: error.message
    });
  }
});

module.exports = router;
