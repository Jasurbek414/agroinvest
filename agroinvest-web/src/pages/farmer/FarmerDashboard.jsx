import React, { useState, useEffect } from 'react';
import { Plus } from 'lucide-react';
import { getMyProjects } from '../../api/projects.api';
import { getMyDashboard } from '../../api/dashboard.api';
import ProjectListTab from '../../components/farmer/ProjectListTab';
import CreateProjectForm from '../../components/farmer/CreateProjectForm';
import ReportUploadModal from '../../components/reports/ReportUploadModal';
import ExpenseFormModal from '../../components/farmer/ExpenseFormModal';
import VetUploadModal from '../../components/farmer/VetUploadModal';
import FarmerStatsBar from '../../components/farmer/FarmerStatsBar';
import ReportsDueBanner from '../../components/farmer/ReportsDueBanner';
import SupportersTab from '../../components/farmer/SupportersTab';
import FinanceTab from '../../components/farmer/FinanceTab';
import ReviewsTab from '../../components/farmer/ReviewsTab';

const TABS = [
  { key: 'list', label: 'Loyihalarim' },
  { key: 'supporters', label: 'Sarmoyadorlarim' },
  { key: 'finance', label: 'Moliya' },
  { key: 'reviews', label: 'Reyting' },
];

// Thin orchestrator for the farmer cabinet: owns the shared data (projects
// page + dashboard aggregates) and the action modals; each tab's rendering
// and per-tab fetches live in components/farmer/*.
const FarmerDashboard = () => {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('list');
  const [stats, setStats] = useState(null);

  const [selectedProjectId, setSelectedProjectId] = useState(null); // report modal
  const [expenseTarget, setExpenseTarget] = useState(null); // { projectId, expensePolicy }
  const [vetTargetProjectId, setVetTargetProjectId] = useState(null);

  useEffect(() => {
    fetchFarmerProjects();
    fetchStats();
  }, []);

  const fetchFarmerProjects = async () => {
    setLoading(true);
    try {
      const res = await getMyProjects();
      setProjects(res.data.content || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      const res = await getMyDashboard();
      setStats(res.data);
    } catch (err) {
      console.error(err);
    }
  };

  const refreshAll = () => {
    fetchFarmerProjects();
    fetchStats();
  };

  return (
    <div className="min-h-screen bg-gray-50/40 dark:bg-slate-950 p-6 md:p-12 transition-all duration-300">
      <div className="max-w-5xl mx-auto space-y-8 animate-in fade-in duration-350">

        {/* Title and top tab switcher */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-2xl md:text-3xl font-black text-gray-950 dark:text-slate-100 tracking-tight">Fermer Ish Stoli</h1>
            <p className="text-xs sm:text-sm text-gray-550 dark:text-slate-400 mt-1">Loyihalaringiz ko'rsatkichlari, sarmoyadorlar nazorati va moliyaviy hisobotlar paneli</p>
          </div>

          <div className="flex flex-wrap bg-white dark:bg-slate-900 p-1.5 rounded-2xl border border-gray-150/40 dark:border-slate-800/80 shadow-sm shrink-0">
            {TABS.map((tab) => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={`px-4 py-2 text-xs font-bold rounded-xl transition duration-200 ${
                  activeTab === tab.key ? 'bg-primary-600 text-white shadow-sm' : 'text-gray-500 dark:text-slate-400 hover:text-primary-600 dark:hover:text-primary-400'
                }`}
              >
                {tab.label}
              </button>
            ))}
            <button
              onClick={() => setActiveTab('create')}
              className={`px-4 py-2 text-xs font-bold rounded-xl transition duration-200 flex items-center gap-1 ${
                activeTab === 'create' ? 'bg-primary-600 text-white shadow-sm' : 'text-gray-500 dark:text-slate-400 hover:text-primary-600 dark:hover:text-primary-400'
              }`}
            >
              <Plus size={14} />
              <span>Yangi Loyiha</span>
            </button>
          </div>
        </div>

        <FarmerStatsBar stats={stats} />

        <ReportsDueBanner stats={stats} onReportClick={setSelectedProjectId} />

        {activeTab === 'list' && (
          <ProjectListTab
            projects={projects}
            loading={loading}
            onCreateClick={() => setActiveTab('create')}
            onReportClick={setSelectedProjectId}
            onExpenseClick={(projectId, expensePolicy) => setExpenseTarget({ projectId, expensePolicy })}
            onVetClick={setVetTargetProjectId}
          />
        )}

        {activeTab === 'supporters' && <SupportersTab projects={projects} />}

        {activeTab === 'finance' && <FinanceTab projects={projects} stats={stats} />}

        {activeTab === 'reviews' && <ReviewsTab />}

        {activeTab === 'create' && (
          <CreateProjectForm
            onCreated={() => {
              setActiveTab('list');
              refreshAll();
            }}
          />
        )}

      </div>

      {/* Modals for actions */}
      {selectedProjectId && (
        <ReportUploadModal
          projectId={selectedProjectId}
          onClose={() => setSelectedProjectId(null)}
          onSubmitted={refreshAll}
        />
      )}

      {expenseTarget && (
        <ExpenseFormModal
          projectId={expenseTarget.projectId}
          expensePolicy={expenseTarget.expensePolicy}
          onClose={() => setExpenseTarget(null)}
          onSubmitted={refreshAll}
        />
      )}

      {vetTargetProjectId && (
        <VetUploadModal
          projectId={vetTargetProjectId}
          onClose={() => setVetTargetProjectId(null)}
          onSubmitted={refreshAll}
        />
      )}

    </div>
  );
};

export default FarmerDashboard;
