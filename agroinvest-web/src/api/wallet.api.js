import api from './axios';

export const getWalletStatus = () => {
  return api.get('/wallet');
};

export const getTransactionHistory = (page = 0, size = 12) => {
  return api.get('/wallet/transactions', { params: { page, size } });
};

export const requestWithdrawal = (amount, bankName, cardNumber) => {
  return api.post('/withdrawals', { amount, bankName, cardNumber });
};
