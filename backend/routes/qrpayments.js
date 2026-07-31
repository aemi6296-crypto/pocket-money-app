const express = require('express');
const router = express.Router();
const { admin, db } = require('../config/firebase');


router.get('/test', (req, res) => {
  res.json({ message: 'QR routes working ✅' });
});


router.get('/vendor/:vendorId', async (req, res) => {
  const { vendorId } = req.params;

  try {
    const vendorDoc = await db.collection('vendors').doc(vendorId).get();

    if (!vendorDoc.exists) {
      return res.status(404).json({ message: 'Vendor not found' });
    }

    const vendor = vendorDoc.data();

    res.status(200).json({
      message: 'Vendor found ✅',
      vendorId,
      vendorName: vendor.vendorName,
      location: vendor.location
    });

  } catch (error) {
    res.status(500).json({
      message: 'Failed to get vendor ❌',
      error: error.message
    });
  }
});


router.post('/pay', async (req, res) => {
  const { kidId, vendorId, amount } = req.body;

  if (!kidId || !vendorId || !amount) {
    return res.status(400).json({ 
      message: 'kidId, vendorId and amount are required' 
    });
  }

  if (amount <= 0) {
    return res.status(400).json({ 
      message: 'Amount must be greater than 0' 
    });
  }

  try {
    const vendorDoc = await db.collection('vendors').doc(vendorId).get();
    if (!vendorDoc.exists) {
      return res.status(404).json({ message: 'Vendor not found' });
    }

    const kidWalletRef = db.collection('wallets').doc(kidId);
    const vendorWalletRef = db.collection('wallets').doc(vendorId);

    await db.runTransaction(async (t) => {
      const kidWallet = await t.get(kidWalletRef);
      const vendorWallet = await t.get(vendorWalletRef);

      if (!kidWallet.exists) throw new Error('Kid wallet not found');
      if (!vendorWallet.exists) throw new Error('Vendor wallet not found');

      const kidBalance = kidWallet.data().balance;
      if (kidBalance < amount) throw new Error('Insufficient balance');

      t.update(kidWalletRef, {
        balance: admin.firestore.FieldValue.increment(-amount)
      });

      t.update(vendorWalletRef, {
        balance: admin.firestore.FieldValue.increment(amount)
      });

      const transactionRef = db.collection('transactions').doc();
      t.set(transactionRef, {
        senderId: kidId,
        receiverId: vendorId,
        vendorName: vendorDoc.data().vendorName,
        amount,
        type: 'qr_payment',
        description: `Payment to ${vendorDoc.data().vendorName}`,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    res.status(200).json({ 
      message: 'Payment successful ✅',
      amount,
      vendorName: vendorDoc.data().vendorName
    });

  } catch (error) {
    if (error.message === 'Insufficient balance') {
      return res.status(400).json({ message: 'Insufficient balance ❌' });
    }
    res.status(500).json({
      message: 'Payment failed ❌',
      error: error.message
    });
  }
});

module.exports = router;

