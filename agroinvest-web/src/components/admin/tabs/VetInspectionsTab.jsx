import React, { useEffect, useState } from 'react';
import { 
  getPendingVetInspections, 
  verifyVetInspection,
  getSuperAdminVeterinarians,
  createVeterinarian,
  deleteVeterinarian 
} from '../../../api/vet.api';
import { formatDate } from '../../../utils/format';
import { HeartPulse, ShieldAlert, Award, FileText, Stethoscope, Eye, Calendar, UserCheck, Plus, Trash2, Phone, UserPlus } from 'lucide-react';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';

const VetInspectionsTab = ({ onActionDone }) => {
  const [activeSubTab, setActiveSubTab] = useState('INSPECTIONS'); // 'INSPECTIONS' | 'VETERINARIANS'
  
  // Inspection states
  const [inspections, setInspections] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const [selectedInspection, setSelectedInspection] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [healthFilter, setHealthFilter] = useState('');

  // Veterinarian states
  const [vets, setVets] = useState([]);
  const [vetsLoading, setVetsLoading] = useState(false);
  const [showAddVetModal, setShowAddVetModal] = useState(false);
  const [newVetData, setNewVetData] = useState({ name: '', licenseNo: '', phone: '', specialty: '' });
  
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getPendingVetInspections(page, 15);
      setInspections(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError('Veterinar hujjatlarini yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  const fetchVets = async () => {
    setVetsLoading(true);
    try {
      const res = await getSuperAdminVeterinarians();
      setVets(res.data || []);
    } catch (err) {
      showToast('Veterinarlar ro\'yxatini yuklab bo\'lmadi', 'error');
    } finally {
      setVetsLoading(false);
    }
  };

  useEffect(() => {
    fetchData(0);
    fetchVets();
  }, []);

  const runAction = async (id, approve, comment) => {
    try {
      await verifyVetInspection(id, approve, comment);
      showToast(approve ? 'Hujjat tasdiqlandi' : 'Hujjat rad etildi');
      fetchData(pageInfo.pageNumber);
      setSelectedInspection(null);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const handleAddVet = async (e) => {
    e.preventDefault();
    if (!newVetData.name || !newVetData.licenseNo) {
      showToast('Ism va Litsenziya raqami kiritilishi shart', 'error');
      return;
    }
    try {
      await createVeterinarian(newVetData);
      showToast('Yangi veterinar muvaffaqiyatli qo\'shildi');
      setShowAddVetModal(false);
      setNewVetData({ name: '', licenseNo: '', phone: '', specialty: '' });
      fetchVets();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const handleDeleteVet = async (id) => {
    if (!window.confirm('Ushbu veterinarni tizimdan o\'chirishni tasdiqlaysizmi?')) return;
    try {
      await deleteVeterinarian(id);
      showToast('Veterinar o\'chirildi');
      fetchVets();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const filteredInspections = inspections.filter(v => {
    const matchesSearch = v.projectTitle?.toLowerCase().includes(searchQuery.toLowerCase()) || 
                          v.vetName?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesHealth = healthFilter ? v.healthStatus === healthFilter : true;
    return matchesSearch && matchesHealth;
  });

  const pendingCount = inspections.length;
  const healthyCount = inspections.filter(v => v.healthStatus === 'HEALTHY' || v.healthStatus === 'SOGLOM').length;

  return (
    <div className="space-y-6 p-6">
      {/* Stats bar */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-amber-50/50 dark:bg-amber-950/10 border border-amber-100 dark:border-amber-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-amber-500/10 text-amber-600 dark:text-amber-400 rounded-xl shrink-0">
            <HeartPulse size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-550 dark:text-slate-400 font-semibold uppercase tracking-wider">Kutilayotgan tekshiruvlar</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{pendingCount} ta hujjat</p>
          </div>
        </div>

        <div className="bg-green-50/50 dark:bg-green-950/10 border border-green-100 dark:border-green-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-green-500/10 text-green-600 dark:text-green-400 rounded-xl shrink-0">
            <Stethoscope size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-550 dark:text-slate-400 font-semibold uppercase tracking-wider">Sog'lom korxonalar</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{healthyCount} ta loyiha</p>
          </div>
        </div>

        <div className="bg-primary-50/50 dark:bg-primary-950/10 border border-primary-100 dark:border-primary-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-primary-500/10 text-primary-600 dark:text-primary-400 rounded-xl shrink-0">
            <Award size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-550 dark:text-slate-400 font-semibold uppercase tracking-wider">Tizim Veterinarlari</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{vets.length} nafar shifokor</p>
          </div>
        </div>
      </div>

      {/* Sub-tab selection */}
      <div className="flex items-center justify-between border-b border-gray-100 dark:border-slate-800 pb-2">
        <div className="flex items-center gap-2">
          <button
            onClick={() => setActiveSubTab('INSPECTIONS')}
            className={`px-4 py-2 text-xs font-bold border-b-2 transition ${
              activeSubTab === 'INSPECTIONS'
                ? 'border-primary-600 text-primary-600 dark:text-primary-400 font-extrabold'
                : 'border-transparent text-gray-400 hover:text-gray-600'
            }`}
          >
            Tekshiruv arizalari ({pendingCount})
          </button>
          <button
            onClick={() => setActiveSubTab('VETERINARIANS')}
            className={`px-4 py-2 text-xs font-bold border-b-2 transition ${
              activeSubTab === 'VETERINARIANS'
                ? 'border-primary-600 text-primary-600 dark:text-primary-400 font-extrabold'
                : 'border-transparent text-gray-400 hover:text-gray-600'
            }`}
          >
            Tizim Veterinarlari ({vets.length})
          </button>
        </div>

        {activeSubTab === 'VETERINARIANS' && (
          <Button 
            variant="primary" 
            size="sm" 
            icon={Plus} 
            onClick={() => setShowAddVetModal(true)}
          >
            Veterinar qo'shish
          </Button>
        )}
      </div>

      {/* Main Content Render */}
      {activeSubTab === 'INSPECTIONS' ? (
        <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm overflow-hidden">
          <DataTable
            loading={loading}
            error={error}
            onRetry={() => fetchData(pageInfo.pageNumber)}
            rows={filteredInspections}
            emptyTitle="Tasdiqlanish kutilayotgan hujjatlar yo'q"
            searchable
            search={searchQuery}
            onSearchChange={setSearchQuery}
            searchPlaceholder="Loyiha yoki veterinar ismi bo'yicha..."
            filters={
              <select
                value={healthFilter}
                onChange={(e) => setHealthFilter(e.target.value)}
                className="px-3 py-2 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500"
              >
                <option value="">Barcha holatlar</option>
                <option value="HEALTHY">Sog'lom (Healthy)</option>
                <option value="TREATMENT">Davolanishda</option>
                <option value="QUARANTINE">Karantinda</option>
              </select>
            }
            page={{ ...pageInfo, onPageChange: fetchData }}
            columns={[
              { key: 'projectTitle', header: 'Loyiha', render: (v) => <span className="font-semibold text-gray-900 dark:text-slate-100">{v.projectTitle}</span> },
              { key: 'vetName', header: 'Veterinar Shifokor', render: (v) => (
                <div>
                  <p className="font-semibold text-gray-950 dark:text-slate-100 text-xs">{v.vetName}</p>
                  {v.vetLicenseNo && <p className="text-[10px] text-gray-400 font-mono">Lic: {v.vetLicenseNo}</p>}
                </div>
              )},
              { key: 'inspectionDate', header: 'Sana', render: (v) => <span className="text-xs text-gray-500 dark:text-slate-400">{formatDate(v.inspectionDate)}</span> },
              { key: 'healthStatus', header: 'Sog\'liq Holati', render: (v) => <Badge status={v.healthStatus} /> },
              { key: 'documentUrls', header: 'Hujjatlar', render: (v) => v.documentUrls && v.documentUrls.length > 0 ? (
                <button 
                  onClick={() => setSelectedInspection(v)}
                  className="flex items-center gap-1.5 px-3 py-1 bg-gray-50 dark:bg-slate-955 border border-gray-100 dark:border-slate-800 rounded-lg text-xs text-primary-600 hover:text-primary-700 font-bold transition shadow-sm"
                >
                  <FileText size={14} />
                  Ko'rish
                </button>
              ) : <span className="text-xs text-gray-400">Yo'q</span> },
              {
                key: 'actions', header: 'Amallar', align: 'right',
                render: (v) => (
                  <div className="flex justify-end gap-1.5">
                    <Button variant="ghost" size="sm" icon={Eye} onClick={() => setSelectedInspection(v)}>Batafsil</Button>
                    <Button variant="danger" size="sm" onClick={() => setRejectTarget(v.id)}>Rad etish</Button>
                    <Button variant="primary" size="sm" onClick={() => runAction(v.id, true, null)}>Tasdiqlash</Button>
                  </div>
                ),
              },
            ]}
            renderMobileCard={(v) => (
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="font-bold text-gray-950 dark:text-slate-100">{v.projectTitle}</span>
                  <Badge status={v.healthStatus} />
                </div>
                <p className="text-xs text-gray-600 dark:text-slate-400">{v.vetName} · {formatDate(v.inspectionDate)}</p>
                {v.conclusion && <p className="text-xs text-gray-500 dark:text-slate-400 italic">"{v.conclusion}"</p>}
                <div className="flex gap-2 pt-1">
                  <Button variant="secondary" size="sm" className="flex-1" onClick={() => setSelectedInspection(v)}>Batafsil</Button>
                  <Button variant="danger" size="sm" className="flex-1" onClick={() => setRejectTarget(v.id)}>Rad etish</Button>
                  <Button variant="primary" size="sm" className="flex-1" onClick={() => runAction(v.id, true, null)}>Tasdiqlash</Button>
                </div>
              </div>
            )}
          />
        </div>
      ) : (
        <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm overflow-hidden animate-in fade-in duration-200">
          <DataTable
            loading={vetsLoading}
            error={null}
            onRetry={fetchVets}
            rows={vets}
            emptyTitle="Tizimda ro'yxatga olingan veterinarlar yo'q"
            columns={[
              { key: 'name', header: 'Ism-sharifi', render: (v) => <span className="font-semibold text-gray-900 dark:text-slate-100">{v.name}</span> },
              { key: 'licenseNo', header: 'Litsenziya raqami', render: (v) => <span className="font-mono text-xs text-gray-500 dark:text-slate-400">{v.licenseNo}</span> },
              { key: 'specialty', header: 'Mutaxassisligi', render: (v) => <span className="text-xs text-gray-700 dark:text-slate-350">{v.specialty || 'Chorvachilik mutaxassisi'}</span> },
              { key: 'phone', header: 'Telefon raqami', render: (v) => <span className="text-xs text-gray-550 dark:text-slate-400">{v.phone || 'Kiritilmagan'}</span> },
              { key: 'createdAt', header: 'Qo\'shilgan sana', render: (v) => <span className="text-xs text-gray-400">{formatDate(v.createdAt)}</span> },
              {
                key: 'actions', header: 'Amallar', align: 'right',
                render: (v) => (
                  <Button variant="danger" size="sm" icon={Trash2} onClick={() => handleDeleteVet(v.id)}>O'chirish</Button>
                ),
              },
            ]}
          />
        </div>
      )}

      {/* Details Modal */}
      {selectedInspection && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm transition-opacity">
          <div className="relative w-full max-w-lg bg-white dark:bg-slate-800 rounded-3xl shadow-xl overflow-hidden animate-in fade-in zoom-in duration-200 border border-gray-100 dark:border-slate-700">
            <div className="px-6 py-5 border-b border-gray-100 dark:border-slate-700 flex justify-between items-center bg-gray-50/50 dark:bg-slate-900/30">
              <div>
                <h3 className="text-lg font-bold text-gray-900 dark:text-slate-100">Veterinar hujjati batafsil</h3>
                <p className="text-xs text-gray-550 dark:text-slate-400 mt-0.5">Tekshirilgan sana: {formatDate(selectedInspection.inspectionDate)}</p>
              </div>
              <button onClick={() => setSelectedInspection(null)} className="p-2 rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700 hover:text-gray-600">&times;</button>
            </div>

            <div className="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
              <div className="flex items-center gap-4 pb-4 border-b border-gray-100 dark:border-slate-700">
                <div className="w-12 h-12 rounded-xl bg-green-50 dark:bg-green-950/40 text-green-600 dark:text-green-400 flex items-center justify-center font-extrabold shrink-0">
                  <HeartPulse size={24} />
                </div>
                <div>
                  <h4 className="text-base font-bold text-gray-900 dark:text-slate-100">{selectedInspection.projectTitle}</h4>
                  <p className="text-xs text-gray-500 dark:text-slate-400">Veterinar: {selectedInspection.vetName} {selectedInspection.vetLicenseNo ? `(Lic: ${selectedInspection.vetLicenseNo})` : ''}</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-xs text-gray-400 font-medium">Sog'liq holati</p>
                  <div className="mt-1"><Badge status={selectedInspection.healthStatus} /></div>
                </div>
                <div>
                  <p className="text-xs text-gray-400 font-medium">Shifokor xulosasi</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100 mt-1">Tekshiruv o'tgan</p>
                </div>
              </div>

              {selectedInspection.conclusion && (
                <div className="space-y-1">
                  <p className="text-xs text-gray-400 font-bold uppercase">Xulosa va Izohlar</p>
                  <p className="text-sm text-gray-700 dark:text-slate-200 leading-relaxed bg-gray-50 dark:bg-slate-900/40 p-3 rounded-xl border border-gray-100 dark:border-slate-800">
                    {selectedInspection.conclusion}
                  </p>
                </div>
              )}

              {selectedInspection.documentUrls && selectedInspection.documentUrls.length > 0 && (
                <div className="space-y-2">
                  <p className="text-xs text-gray-400 font-bold uppercase">Yuklangan ma'lumotnomalar / Hujjatlar</p>
                  <div className="grid grid-cols-2 gap-2">
                    {selectedInspection.documentUrls.map((url, idx) => (
                      <div key={idx} className="border border-gray-100 dark:border-slate-700 rounded-xl overflow-hidden bg-gray-50 flex items-center justify-center relative group min-h-28">
                        <img src={url} alt="Hujjat" className="h-28 w-full object-cover" />
                        <a 
                          href={url} 
                          target="_blank" 
                          rel="noopener noreferrer" 
                          className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-xs font-bold transition gap-1"
                        >
                          <Eye size={14} /> Ochish
                        </a>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <div className="px-6 py-4 border-t border-gray-100 dark:border-slate-700 bg-gray-50/50 dark:bg-slate-900/30 flex justify-end gap-2">
              <Button variant="secondary" onClick={() => setSelectedInspection(null)}>Yopish</Button>
              <Button variant="danger" onClick={() => setRejectTarget(selectedInspection.id)}>Rad etish</Button>
              <Button variant="primary" onClick={() => runAction(selectedInspection.id, true, null)}>Tasdiqlash</Button>
            </div>
          </div>
        </div>
      )}

      {/* Add Veterinarian Modal */}
      {showAddVetModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm transition-opacity">
          <div className="relative w-full max-w-md bg-white dark:bg-slate-800 rounded-3xl shadow-xl overflow-hidden animate-in fade-in zoom-in duration-200 border border-gray-100 dark:border-slate-700">
            <div className="px-6 py-5 border-b border-gray-100 dark:border-slate-700 bg-gray-50/50 dark:bg-slate-900/30">
              <h3 className="text-lg font-bold text-gray-900 dark:text-slate-100">Yangi veterinar shifokor qo'shish</h3>
            </div>
            
            <form onSubmit={handleAddVet} className="p-6 space-y-4">
              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase tracking-wide">Ism-sharifi (F.I.SH) *</label>
                <input 
                  type="text" 
                  value={newVetData.name} 
                  onChange={(e) => setNewVetData({ ...newVetData, name: e.target.value })}
                  placeholder="Masalan: Asrorov Bobur" 
                  className="w-full px-4 py-2.5 border border-gray-200 dark:border-slate-700 bg-gray-50/10 dark:bg-slate-900 text-xs font-semibold rounded-xl outline-none focus:ring-1 focus:ring-primary-500 text-gray-900 dark:text-white"
                  required
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase tracking-wide">Litsenziya raqami *</label>
                <input 
                  type="text" 
                  value={newVetData.licenseNo} 
                  onChange={(e) => setNewVetData({ ...newVetData, licenseNo: e.target.value })}
                  placeholder="Masalan: VET-2026-1049" 
                  className="w-full px-4 py-2.5 border border-gray-200 dark:border-slate-700 bg-gray-50/10 dark:bg-slate-900 text-xs font-semibold rounded-xl outline-none focus:ring-1 focus:ring-primary-500 text-gray-900 dark:text-white"
                  required
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase tracking-wide">Telefon raqami</label>
                <input 
                  type="text" 
                  value={newVetData.phone} 
                  onChange={(e) => setNewVetData({ ...newVetData, phone: e.target.value })}
                  placeholder="Masalan: +998901234567" 
                  className="w-full px-4 py-2.5 border border-gray-200 dark:border-slate-700 bg-gray-50/10 dark:bg-slate-900 text-xs font-semibold rounded-xl outline-none focus:ring-1 focus:ring-primary-500 text-gray-900 dark:text-white"
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase tracking-wide">Mutaxassisligi</label>
                <input 
                  type="text" 
                  value={newVetData.specialty} 
                  onChange={(e) => setNewVetData({ ...newVetData, specialty: e.target.value })}
                  placeholder="Masalan: Yirik shoxli chorva, parrandachilik" 
                  className="w-full px-4 py-2.5 border border-gray-200 dark:border-slate-700 bg-gray-50/10 dark:bg-slate-900 text-xs font-semibold rounded-xl outline-none focus:ring-1 focus:ring-primary-500 text-gray-900 dark:text-white"
                />
              </div>

              <div className="flex justify-end gap-2 pt-4">
                <Button variant="secondary" type="button" onClick={() => setShowAddVetModal(false)}>Bekor qilish</Button>
                <Button variant="primary" type="submit">Qo'shish</Button>
              </div>
            </form>
          </div>
        </div>
      )}

      <PromptDialog
        open={!!rejectTarget}
        title="Veterinar hujjatini rad etish"
        label="Izoh"
        tone="danger"
        confirmLabel="Rad etish"
        onCancel={() => setRejectTarget(null)}
        onConfirm={(comment) => { runAction(rejectTarget, false, comment); setRejectTarget(null); }}
      />
    </div>
  );
};

export default VetInspectionsTab;
