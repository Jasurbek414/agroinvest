import React, { useState, useEffect } from 'react';
import { getMyProjects } from '../../api/projects.api';
import ProjectListTab from '../../components/farmer/ProjectListTab';
import CreateProjectForm from '../../components/farmer/CreateProjectForm';
import ReportUploadModal from '../../components/farmer/ReportUploadModal';

const FarmerDashboard = () => {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('list'); // 'list' | 'create'
  const [selectedProjectId, setSelectedProjectId] = useState(null);

  useEffect(() => {
    fetchFarmerProjects();
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

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-slate-900 p-6 md:p-12">
      <div className="max-w-5xl mx-auto space-y-8">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Fermer ish stoli (Farmer Dashboard)</h1>
            <p className="text-sm text-gray-500 mt-1">Loyihalaringiz holati va yangi hisobotlar taqdim etish paneli</p>
          </div>
          <div className="flex bg-white p-1.5 rounded-xl border border-gray-100 shadow-sm">
            <button
              onClick={() => setActiveTab('list')}
              className={`px-4 py-2 text-xs font-bold rounded-lg transition ${
                activeTab === 'list' ? 'bg-green-600 text-white shadow-sm' : 'text-gray-500 hover:text-green-600'
              }`}
            >
              Loyihalarim
            </button>
            <button
              onClick={() => setActiveTab('create')}
              className={`px-4 py-2 text-xs font-bold rounded-lg transition ${
                activeTab === 'create' ? 'bg-green-600 text-white shadow-sm' : 'text-gray-500 hover:text-green-600'
              }`}
            >
              + Loyiha qo'shish
            </button>
          </div>
        </div>

        {activeTab === 'list' ? (
          <ProjectListTab
            projects={projects}
            loading={loading}
            onCreateClick={() => setActiveTab('create')}
            onReportClick={setSelectedProjectId}
          />
        ) : (
          <CreateProjectForm
            onCreated={() => {
              setActiveTab('list');
              fetchFarmerProjects();
            }}
          />
        )}
      </div>

      {selectedProjectId && (
        <ReportUploadModal
          projectId={selectedProjectId}
          onClose={() => setSelectedProjectId(null)}
          onSubmitted={() => setSelectedProjectId(null)}
        />
      )}
    </div>
  );
};

export default FarmerDashboard;
