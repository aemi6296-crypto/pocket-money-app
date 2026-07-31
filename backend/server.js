const express = require('express');
const cors = require('cors');
const vendorRoutes = require('./routes/vendor');
const authRoutes = require('./routes/auth');
const transferRoutes = require('./routes/transfer');
const qrRoutes = require('./routes/qrpayments');
const expenseRoutes = require('./routes/expenses');
const choreRoutes = require('./routes/chores');
const piggybankRoutes = require('./routes/piggybank');
const wishlistRoutes = require('./routes/wishlist');
const reportRoutes = require('./routes/reports');
const notificationRoutes = require('./routes/notifications');
const walletRoutes = require('./routes/wallet');
const badgeRoutes = require('./routes/badges');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/api/chores', choreRoutes);
app.use('/api/piggybank', piggybankRoutes);
app.use('/api/wishlist',wishlistRoutes);
app.use('/api/reports',reportRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/badges', badgeRoutes);

app.get('/', (req, res) => {
  res.send('API is working 🚀');
});

app.use('/api/auth', authRoutes);
app.use('/api/transfer', transferRoutes);
app.use('/api/qr', qrRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/vendor', vendorRoutes);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Backend Server is running on port ${PORT}`);
});
