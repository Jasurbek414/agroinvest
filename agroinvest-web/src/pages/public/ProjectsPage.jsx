import React, { useState, useEffect } from 'react';
import { getProjects } from '../../api/projects.api';
import ProjectCard from '../../components/projects/ProjectCard';
import ProjectFilters from '../../components/projects/ProjectFilters';

const ProjectsPage = () => {
  const [projects, setProjects] = useState([]);
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchProjects();
  }, [status]);

  const fetchProjects = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await getProjects(status);
      setProjects(response.data.content || []);
    } catch (err) {
      setError("Loyihalarni yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50/50 p-6 md:p-12">
      <div className="max-w-6xl mx-auto space-y-8">
        <div>
          <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Investitsiya loyihalari</h1>
          <p className="text-gray-500 mt-2">Fermerlarni qo'llab-quvvatlang va birgalikda daromad oling</p>
        </div>

        <ProjectFilters currentStatus={status} onStatusChange={setStatus} />

        {error && (
          <div className="p-4 bg-red-50 text-red-700 rounded-2xl border border-red-100 text-sm">
            {error}
          </div>
        )}

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[1, 2, 3].map((n) => (
              <div key={n} className="bg-white rounded-2xl h-80 animate-pulse border border-gray-100" />
            ))}
          </div>
        ) : projects.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-2xl border border-gray-100">
            <p className="text-gray-400 text-sm">Hozirda ushbu turkumda loyihalar mavjud emas</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {projects.map((project) => (
              <ProjectCard key={project.id} project={project} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default ProjectsPage;
