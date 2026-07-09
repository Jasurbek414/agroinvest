import React from 'react';
import { Plus, Pencil } from 'lucide-react';
import Button from '../ui/Button';

const CategoryTreeNode = ({ node, onAddChild, onEdit }) => {
  return (
    <div>
      <div
        className="flex items-center justify-between gap-3 py-2 border-b border-gray-50 dark:border-slate-700/50"
        style={{ paddingLeft: `${node.level * 20}px` }}
      >
        <div className="flex items-center gap-2 min-w-0">
          <span className={`text-sm truncate ${node.isActive ? 'text-gray-800 dark:text-slate-200' : 'text-gray-400 dark:text-slate-500 line-through'}`}>
            {node.nameUz}
          </span>
          <span className="text-[10px] font-mono text-gray-400 shrink-0">{node.code}</span>
          {!node.isActive && (
            <span className="px-1.5 py-0.5 rounded-full text-[10px] font-bold bg-gray-100 dark:bg-slate-700 text-gray-500 dark:text-slate-400 shrink-0">
              Nofaol
            </span>
          )}
        </div>
        <div className="flex gap-1 shrink-0">
          <Button variant="ghost" size="sm" icon={Plus} onClick={() => onAddChild(node.id)}>Bo'lim</Button>
          <Button variant="ghost" size="sm" icon={Pencil} onClick={() => onEdit(node)} />
        </div>
      </div>
      {node.children?.map((child) => (
        <CategoryTreeNode key={child.id} node={child} onAddChild={onAddChild} onEdit={onEdit} />
      ))}
    </div>
  );
};

export default CategoryTreeNode;
