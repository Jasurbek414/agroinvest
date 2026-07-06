import React, { useState, useEffect } from 'react';
import { getWalletStatus, getTransactionHistory } from '../../api/wallet.api';
import { useAuthStore } from '../../store/auth.store';
import Card from '../../components/ui/Card';
import ErrorState from '../../components/ui/ErrorState';
import TopUpForm from '../../components/wallet/TopUpForm';
import WithdrawalForm from '../../components/wallet/WithdrawalForm';
import TransactionHistoryList from '../../components/wallet/TransactionHistoryList';
import { formatAmount } from '../../utils/format';

const WalletPage = () => {
  const { user } = useAuthStore();
  const [wallet, setWallet] = useState(null);
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [activeTab, setActiveTab] = useState('topup'); // 'topup' | 'withdraw'

  useEffect(() => {
    fetchWalletAndTransactions();
  }, []);

  const fetchWalletAndTransactions = async () => {
    setLoading(true);
    setError(null);
    try {
      const wResponse = await getWalletStatus();
      setWallet(wResponse.data);

      const tResponse = await getTransactionHistory();
      setTransactions(tResponse.data.content || []);
    } catch (err) {
      setError("Hamyon ma'lumotlarini yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50/50 p-6 md:p-12">
      <div className="max-w-4xl mx-auto space-y-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Mening Hamyonim</h1>
          <p className="text-sm text-gray-500 mt-1">Balansni to'ldiring, foyda va sarmoyalar tranzaksiyalarini kuzating</p>
        </div>

        {error ? (
          <ErrorState message={error} onRetry={fetchWalletAndTransactions} />
        ) : (
          <>
            {/* Balance cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <Card>
                <p className="text-xs text-gray-400 font-semibold uppercase">Erkin balans</p>
                <p className="text-2xl font-black text-green-600 mt-2">{formatAmount(wallet?.balance)}</p>
              </Card>
              <Card>
                <p className="text-xs text-gray-400 font-semibold uppercase">Muzlatilgan sarmoya</p>
                <p className="text-2xl font-black text-yellow-600 mt-2">{formatAmount(wallet?.frozen)}</p>
              </Card>
              <Card>
                <p className="text-xs text-gray-400 font-semibold uppercase">Umumiy yechilgan</p>
                <p className="text-2xl font-black text-gray-700 mt-2">{formatAmount(wallet?.totalWithdrawn)}</p>
              </Card>
            </div>

            {/* Top-up / Withdraw */}
            <Card>
              <div className="flex bg-gray-50 p-1 rounded-xl mb-6 w-fit">
                <button
                  onClick={() => setActiveTab('topup')}
                  className={`px-4 py-2 text-xs font-bold rounded-lg transition ${
                    activeTab === 'topup' ? 'bg-white shadow-sm text-green-700' : 'text-gray-500'
                  }`}
                >
                  Balansni to'ldirish
                </button>
                <button
                  onClick={() => setActiveTab('withdraw')}
                  className={`px-4 py-2 text-xs font-bold rounded-lg transition ${
                    activeTab === 'withdraw' ? 'bg-white shadow-sm text-green-700' : 'text-gray-500'
                  }`}
                >
                  Pul yechish
                </button>
              </div>

              {activeTab === 'topup' ? (
                <TopUpForm userId={user?.id} />
              ) : (
                <WithdrawalForm balance={wallet?.balance} onRequested={fetchWalletAndTransactions} />
              )}
            </Card>

            {/* Transactions list */}
            <Card padded={false} className="overflow-hidden">
              <div className="p-6 border-b border-gray-100">
                <h2 className="text-lg font-bold text-gray-900">Tranzaksiyalar tarixi</h2>
              </div>
              <TransactionHistoryList transactions={transactions} loading={loading} />
            </Card>
          </>
        )}
      </div>
    </div>
  );
};

export default WalletPage;
