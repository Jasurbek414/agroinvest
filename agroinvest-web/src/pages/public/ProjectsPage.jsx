import React, { useState, useEffect } from 'react';
import { getProjects } from '../../api/projects.api';
import ProjectCard from '../../components/projects/ProjectCard';
import ProjectFilters from '../../components/projects/ProjectFilters';
import { Sprout, Sparkles, FolderKanban, Search, HelpCircle, Loader2 } from 'lucide-react';

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
      const response = await getProjects(status || undefined);
      setProjects(response.data.content || []);
    } catch (err) {
      setError("Loyihalarni yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50/40 dark:bg-slate-950 p-6 md:p-12 transition-all duration-300">
      <div className="max-w-6xl mx-auto space-y-8 animate-in fade-in duration-300">
        
        {/* Premium Banner Header */}
        <div className="relative overflow-hidden p-8 md:p-10 border border-emerald-500/10 dark:border-slate-800 bg-gradient-to-br from-slate-900 via-slate-950 to-primary-950 text-white rounded-[32px] shadow-xl">
          <div className="absolute top-0 right-0 w-80 h-80 bg-primary-500/10 rounded-full blur-3xl -z-10" />
          <div className="absolute bottom-0 left-10 w-60 h-60 bg-emerald-500/5 rounded-full blur-3xl -z-10" />
          
          <div className="flex items-center gap-2">
            <span className="px-2.5 py-0.5 rounded-full bg-primary-500/20 text-primary-300 text-[10px] font-bold tracking-wider uppercase">Loyiha katalogi</span>
            <Sparkles size={12} className="text-amber-400 animate-pulse" />
          </div>

          <h1 className="text-2xl md:text-4xl font-black text-white mt-2 tracking-tight">Investitsiya Loyihalari</h1>
          <p className="text-gray-300 text-xs md:text-sm mt-1 max-w-xl leading-relaxed">
            Platformaning barcha faol investitsiya loyihalari ro'yxati. Dehqonchilik, chorvachilik va bog'dorchilik loyihalarini qo'llab-quvvatlang va birgalikda daromadga ega bo'ling.
          </p>
        </div>

        {/* Filter bar */}
        <div className="bg-white dark:bg-slate-900 p-4 rounded-3xl border border-gray-150/40 dark:border-slate-800/80 shadow-sm flex flex-col gap-4">
          <p className="text-[10px] font-bold text-gray-400 dark:text-slate-500 uppercase tracking-wider pl-1">Loyihalar holati</p>
          <ProjectFilters currentStatus={status} onStatusChange={setStatus} />
        </div>

        {error && (
          <div className="p-4 bg-rose-50 dark:bg-rose-950/20 text-rose-700 dark:text-rose-400 rounded-2xl border border-rose-100 dark:border-rose-900/30 text-xs font-semibold">
            {error}
          </div>
        )}

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[1, 2, 3].map((n) => (
              <div key={n} className="h-[360px] rounded-3xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 animate-pulse p-6 space-y-4 shadow-sm">
                <div className="flex justify-between"><div className="w-20 h-8 bg-gray-200 dark:bg-slate-800 rounded-lg animate-pulse" /><div className="w-16 h-8 bg-gray-200 dark:bg-slate-800 rounded-full animate-pulse" /></div>
                <div className="w-3/4 h-6 bg-gray-200 dark:bg-slate-800 rounded-lg animate-pulse" />
                <div className="w-1/2 h-4 bg-gray-200 dark:bg-slate-800 rounded-lg animate-pulse" />
                <div className="h-16 bg-gray-100 dark:bg-slate-800/50 rounded-xl animate-pulse" />
                <div className="h-10 bg-gray-200 dark:bg-slate-800 rounded-xl animate-pulse" />
              </div>
            ))}
          </div>
        ) : projects.length === 0 ? (
          <div className="text-center py-20 bg-white dark:bg-slate-900 rounded-[32px] border border-gray-100 dark:border-slate-800/80 shadow-sm">
            <HelpCircle className="mx-auto text-gray-300 dark:text-slate-700" size={56} />
            <h3 className="text-lg font-bold text-gray-800 dark:text-slate-200 mt-4">Loyihalar mavjud emas</h3>
            <p className="text-xs text-gray-500 dark:text-slate-500 mt-1">Ushbu holat bo'yicha ayni vaqtda faol loyihalar topilmadi</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 animate-in fade-in duration-300">
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
