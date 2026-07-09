import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import { getProjects } from '../../api/projects.api';
import ProjectCard from '../projects/ProjectCard';

const FeaturedProjectsSection = () => {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getProjects('FUNDING', 0, 3)
      .then((res) => setProjects(res.data.content || []))
      .finally(() => setLoading(false));
  }, []);

  if (!loading && projects.length === 0) return null;

  return (
    <section className="bg-gray-50/60 dark:bg-slate-900/60 py-16 md:py-24">
      <div className="max-w-6xl mx-auto px-6">
        <div className="flex items-end justify-between mb-8">
          <div>
            <h2 className="text-2xl md:text-3xl font-extrabold text-gray-900 dark:text-slate-100">Faol loyihalar</h2>
            <p className="text-gray-500 dark:text-slate-400 mt-2">Hozir mablag' yig'ayotgan tanlangan loyihalar</p>
          </div>
          <Link to="/projects" className="hidden sm:inline-flex items-center gap-1 text-sm font-semibold text-primary-700 dark:text-primary-400 hover:underline shrink-0">
            Barchasini ko'rish <ArrowRight size={14} />
          </Link>
        </div>

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {[1, 2, 3].map((n) => (
              <div key={n} className="bg-white dark:bg-slate-800 rounded-2xl h-80 animate-pulse border border-gray-100 dark:border-slate-700" />
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {projects.map((project) => (
              <ProjectCard key={project.id} project={project} />
            ))}
          </div>
        )}

        <div className="mt-8 text-center sm:hidden">
          <Link to="/projects" className="inline-flex items-center gap-1 text-sm font-semibold text-primary-700 dark:text-primary-400 hover:underline">
            Barchasini ko'rish <ArrowRight size={14} />
          </Link>
        </div>
      </div>
    </section>
  );
};

export default FeaturedProjectsSection;
