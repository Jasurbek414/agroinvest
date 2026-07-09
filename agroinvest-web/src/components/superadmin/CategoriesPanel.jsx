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

  return (
    <Card>
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">Aktiv kategoriyalari</h2>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">3 darajali taksonomiya (Chorvachilik → Qoramolchilik → Sut ...)</p>
        </div>
        <Button variant="primary" size="sm" icon={Plus} onClick={() => setFormState({ mode: 'create', parentId: null })}>
          Yangi kategoriya
        </Button>
      </div>

      {loading ? (
        <p className="text-sm text-gray-400 text-center py-6">Yuklanmoqda...</p>
      ) : tree.length === 0 ? (
        <p className="text-sm text-gray-400 text-center py-6">Kategoriyalar topilmadi</p>
      ) : (
        <div>
          {tree.map((node) => (
            <CategoryTreeNode
              key={node.id}
              node={node}
              onAddChild={(parentId) => setFormState({ mode: 'create', parentId })}
              onEdit={(category) => setFormState({ mode: 'edit', category })}
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
