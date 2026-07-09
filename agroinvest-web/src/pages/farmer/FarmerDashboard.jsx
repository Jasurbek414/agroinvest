import React, { useState, useEffect } from 'react';
import { getMyProjects } from '../../api/projects.api';
import { getMyDashboard } from '../../api/dashboard.api';
import ProjectListTab from '../../components/farmer/ProjectListTab';
import CreateProjectForm from '../../components/farmer/CreateProjectForm';
import ReportUploadModal from '../../components/reports/ReportUploadModal';
import ExpenseFormModal from '../../components/farmer/ExpenseFormModal';
import VetUploadModal from '../../components/farmer/VetUploadModal';
import FarmerStatsBar from '../../components/farmer/FarmerStatsBar';

const FarmerDashboard = () => {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('list'); // 'list' | 'create'
  const [selectedProjectId, setSelectedProjectId] = useState(null);
  const [expenseTarget, setExpenseTarget] = useState(null); // { projectId, expensePolicy }
  const [vetTargetProjectId, setVetTargetProjectId] = useState(null);
  const [stats, setStats] = useState(null);

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
      // Non-critical - the project list below still works without the stats bar.
      console.error(err);
    }
  };

  const refreshAll = () => {
    fetchFarmerProjects();
    fetchStats();
  };

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-slate-900 p-6 md:p-12">
      <div className="max-w-5xl mx-auto space-y-8">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-slate-100">Fermer ish stoli (Farmer Dashboard)</h1>
            <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">Loyihalaringiz holati va yangi hisobotlar taqdim etish paneli</p>
          </div>
          <div className="flex bg-white dark:bg-slate-800 p-1.5 rounded-xl border border-gray-100 dark:border-slate-700 shadow-sm">
            <button
              onClick={() => setActiveTab('list')}
              className={`px-4 py-2 text-xs font-bold rounded-lg transition ${
                activeTab === 'list' ? 'bg-primary-600 text-white shadow-sm' : 'text-gray-500 dark:text-slate-400 hover:text-primary-600 dark:hover:text-primary-400'
              }`}
            >
              Loyihalarim
            </button>
            <button
              onClick={() => setActiveTab('create')}
              className={`px-4 py-2 text-xs font-bold rounded-lg transition ${
                activeTab === 'create' ? 'bg-primary-600 text-white shadow-sm' : 'text-gray-500 dark:text-slate-400 hover:text-primary-600 dark:hover:text-primary-400'
              }`}
            >
              + Loyiha qo'shish
            </button>
          </div>
        </div>

        <FarmerStatsBar stats={stats} />

        {activeTab === 'list' ? (
          <ProjectListTab
            projects={projects}
            loading={loading}
            onCreateClick={() => setActiveTab('create')}
            onReportClick={setSelectedProjectId}
            onExpenseClick={(projectId, expensePolicy) => setExpenseTarget({ projectId, expensePolicy })}
            onVetClick={setVetTargetProjectId}
          />
        ) : (
          <CreateProjectForm
            onCreated={() => {
              setActiveTab('list');
              refreshAll();
            }}
          />
        )}
      </div>

      {selectedProjectId && (
        <ReportUploadModal
          projectId={selectedProjectId}
          onClose={() => setSelectedProjectId(null)}
          onSubmitted={() => { setSelectedProjectId(null); refreshAll(); }}
        />
      )}

      {expenseTarget && (
        <ExpenseFormModal
          projectId={expenseTarget.projectId}
          expensePolicy={expenseTarget.expensePolicy}
          onClose={() => setExpenseTarget(null)}
          onSubmitted={() => { setExpenseTarget(null); refreshAll(); }}
        />
      )}

      {vetTargetProjectId && (
        <VetUploadModal
          projectId={vetTargetProjectId}
          onClose={() => setVetTargetProjectId(null)}
          onSubmitted={() => { setVetTargetProjectId(null); refreshAll(); }}
        />
      )}
    </div>
  );
};

export default FarmerDashboard;
