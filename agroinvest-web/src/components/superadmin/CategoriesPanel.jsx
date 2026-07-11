import React, { useEffect, useState } from 'react';
import { Plus } from 'lucide-react';
import { getAllCategoriesTree } from '../../api/categories.api';
import Card from '../ui/Card';
import Button from '../ui/Button';
import { useToast } from '../ui/ToastProvider';
import CategoryTreeNode from './CategoryTreeNode';
import CategoryFormModal from './CategoryFormModal';

const CategoriesPanel = () => {
  const [tree, setTree] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [formState, setFormState] = useState(null); // { mode: 'create'|'edit', parentId?, category? }
  const { showToast } = useToast();

  const fetchTree = async () => {
    setLoading(true);
    try {
      const res = await getAllCategoriesTree();
      setTree(res.data || []);
    } catch (err) {
      showToast('Kategoriyalarni yuklashda xatolik yuz berdi', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchTree(); }, []);

  const getStats = (list) => {
    let roots = 0;
    let subcategories = 0;
    let inactive = 0;
    const traverse = (nodes) => {
      nodes.forEach(n => {
        if (n.level === 0) roots++;
        else subcategories++;
        if (!n.isActive) inactive++;
        if (n.children) traverse(n.children);
      });
    };
    traverse(list);
    return { roots, subcategories, inactive };
  };

  const stats = getStats(tree);

  return (
    <Card padded className="space-y-6">
      <div className="flex flex-col md:flex-row gap-4 justify-between items-start md:items-center">
        <div>
          <h2 className="text-lg font-bold text-gray-900 dark:text-slate-100">Aktiv kategoriyalari</h2>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">3 darajali taksonomiya (Chorvachilik → Qoramolchilik → Sut ...)</p>
        </div>
        <div className="flex gap-2 w-full md:w-auto">
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Qidirish (ism yoki kod)..."
            className="px-3.5 py-1.5 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500 w-full md:w-48 placeholder-gray-400"
          />
          <Button variant="primary" size="sm" icon={Plus} onClick={() => setFormState({ mode: 'create', parentId: null })} className="shrink-0">
            Yangi kategoriya
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4 p-4 bg-gray-50/50 dark:bg-slate-900/20 border border-gray-100 dark:border-slate-800 rounded-2xl text-center">
        <div>
          <p className="text-[10px] uppercase font-bold text-gray-400 dark:text-slate-500 tracking-wider">Asosiy yo'nalishlar</p>
          <p className="text-base font-extrabold text-gray-900 dark:text-slate-100 mt-0.5">{stats.roots} ta</p>
        </div>
        <div>
          <p className="text-[10px] uppercase font-bold text-gray-400 dark:text-slate-500 tracking-wider">Ichki bo'limlar</p>
          <p className="text-base font-extrabold text-gray-900 dark:text-slate-100 mt-0.5">{stats.subcategories} ta</p>
        </div>
        <div>
          <p className="text-[10px] uppercase font-bold text-gray-400 dark:text-slate-500 tracking-wider">Nofaol toifalar</p>
          <p className="text-base font-extrabold text-red-600 dark:text-red-400 mt-0.5">{stats.inactive} ta</p>
        </div>
      </div>

      {loading ? (
        <p className="text-sm text-gray-400 text-center py-6">Yuklanmoqda...</p>
      ) : tree.length === 0 ? (
        <p className="text-sm text-gray-400 text-center py-6">Kategoriyalar topilmadi</p>
      ) : (
        <div className="space-y-1">
          {tree.map((node) => (
            <CategoryTreeNode
              key={node.id}
              node={node}
              onAddChild={(parentId) => setFormState({ mode: 'create', parentId })}
              onEdit={(category) => setFormState({ mode: 'edit', category })}
              searchTerm={searchTerm}
            />
          ))}
        </div>
      )}

      {formState && (
        <CategoryFormModal
          mode={formState.mode}
          parentId={formState.parentId}
          category={formState.category}
          onClose={() => setFormState(null)}
          onSaved={() => { setFormState(null); fetchTree(); }}
        />
      )}
    </Card>
  );
};

export default CategoriesPanel;
