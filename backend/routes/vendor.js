const express = require('express');
const router = express.Router();
const QRCode = require('qrcode');
const { admin, db } = require('../config/firebase');


router.post('/register', async (req, res) => {
  const { vendorName, email, location } = req.body;

  if (!vendorName || !email) {
    return res.status(400).json({ 
      message: 'Vendor name and email are required' 
    });
  }

  try {
    const vendorRef = db.collection('vendors').doc();
    const vendorId = vendorRef.id;
    const qrData = JSON.stringify({
      vendorId,
      vendorName,
    });

    const qrImage = await QRCode.toDataURL(qrData);
    await vendorRef.set({
      vendorId,
      vendorName,
      email,
      location: location || '',
      qrCode: qrImage,
      createdAt: new Date()
    });

  
    await db.collection('wallets').doc(vendorId).set({
      balance: 0,
      ownerId: vendorId,
      currency: 'USD',
      createdAt: new Date()
    });

    res.status(201).json({
      message: 'Vendor registered successfully ✅',
      vendorId,
      qrImage  
    });

  } catch (error) {
    res.status(500).json({
      message: 'Vendor registration failed ❌',
      error: error.message
    });
  }
});


router.get('/:vendorId', async (req, res) => {
  const { vendorId } = req.params;

  try {
    const vendorDoc = await db.collection('vendors').doc(vendorId).get();

    if (!vendorDoc.exists) {
      return res.status(404).json({ message: 'Vendor not found' });
    }

    res.status(200).json({
      message: 'Vendor found ✅',
      vendor: vendorDoc.data()
    });

  } catch (error) {
    res.status(500).json({
      message: 'Failed to get vendor ❌',
      error: error.message
    });
  }
});

module.exports = router;
