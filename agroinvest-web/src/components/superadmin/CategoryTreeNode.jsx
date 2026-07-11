import React, { useState } from 'react';
import { Plus, Pencil, ChevronRight, ChevronDown } from 'lucide-react';
import * as Lucide from 'lucide-react';
import Button from '../ui/Button';

const DynamicIcon = ({ name, className, size = 16 }) => {
  const IconComponent = Lucide[name] || Lucide.Folder;
  return <IconComponent className={className} size={size} />;
};

const CategoryTreeNode = ({ node, onAddChild, onEdit, searchTerm }) => {
  const [expanded, setExpanded] = useState(true);
  const hasChildren = node.children && node.children.length > 0;

  // Search logic
  const matchesSearch = searchTerm
    ? node.nameUz.toLowerCase().includes(searchTerm.toLowerCase()) ||
      node.code.toLowerCase().includes(searchTerm.toLowerCase())
    : false;

  const childMatchesSearch = (n) => {
    if (!searchTerm) return false;
    if (n.children) {
      return n.children.some(c => 
        c.nameUz.toLowerCase().includes(searchTerm.toLowerCase()) ||
        c.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
        childMatchesSearch(c)
      );
    }
    return false;
  };

  const isVisible = !searchTerm || matchesSearch || childMatchesSearch(node);

  if (!isVisible) return null;

  return (
    <div className="select-none">
      {/* Node Row */}
      <div
        className={`flex items-center justify-between gap-3 py-2.5 px-3 border-b border-gray-100/50 dark:border-slate-800/40 hover:bg-gray-50/50 dark:hover:bg-slate-800/20 transition rounded-xl ${
          node.level === 0 
            ? 'bg-gray-50/40 dark:bg-slate-900/20 font-bold border-l-4 border-primary-500' 
            : node.level === 1 
            ? 'font-semibold border-l border-gray-200 dark:border-slate-700' 
            : 'text-gray-600 dark:text-slate-300'
        }`}
        style={{ marginLeft: `${node.level * 16}px` }}
      >
        <div className="flex items-center gap-3 min-w-0 flex-1">
          {/* Toggle Button */}
          {hasChildren ? (
            <button
              type="button"
              onClick={() => setExpanded(!expanded)}
              className="p-1 rounded-lg hover:bg-gray-200 dark:hover:bg-slate-700 text-gray-400 hover:text-gray-600 dark:hover:text-slate-200 transition shrink-0"
            >
              {expanded ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
            </button>
          ) : (
            <div className="w-6 h-6 flex items-center justify-center shrink-0">
              <div className="w-1.5 h-1.5 rounded-full bg-gray-300 dark:bg-slate-600" />
            </div>
          )}

          {/* Icon */}
          <div className={`p-1.5 rounded-xl shrink-0 ${
            node.isActive 
              ? 'bg-primary-50 dark:bg-primary-950/40 text-primary-600 dark:text-primary-400' 
              : 'bg-gray-100 dark:bg-slate-800 text-gray-400 dark:text-slate-500'
          }`}>
            <DynamicIcon name={node.icon || 'Folder'} size={14} />
          </div>

          {/* Name & Code */}
          <div className="flex items-center gap-2 min-w-0 flex-wrap">
            <span className={`text-sm truncate ${
              node.isActive 
                ? 'text-gray-800 dark:text-slate-200' 
                : 'text-gray-400 dark:text-slate-500 line-through'
            }`}>
              {node.nameUz}
            </span>
            <span className="text-[10px] font-mono font-semibold px-2 py-0.5 rounded-lg bg-gray-100 dark:bg-slate-800 text-gray-500 dark:text-slate-400 shrink-0">
              {node.code}
            </span>
            {!node.isActive && (
              <span className="px-1.5 py-0.5 rounded-full text-[9px] font-bold bg-red-50 dark:bg-red-950/20 text-red-600 dark:text-red-400 shrink-0">
                Nofaol
              </span>
            )}
            {hasChildren && (
              <span className="text-[10px] text-gray-400 dark:text-slate-500 font-normal shrink-0">
                ({node.children.length} ta bo'lim)
              </span>
            )}
          </div>
        </div>

        {/* Actions */}
        <div className="flex gap-1 shrink-0">
          {node.level < 2 && (
            <Button 
              variant="ghost" 
              size="sm" 
              icon={Plus} 
              onClick={() => onAddChild(node.id)}
              className="text-primary-600 hover:bg-primary-50 dark:hover:bg-primary-950/30"
            >
              Ichki bo'lim
            </Button>
          )}
          <Button 
            variant="ghost" 
            size="sm" 
            icon={Pencil} 
            onClick={() => onEdit(node)}
            className="hover:bg-gray-100 dark:hover:bg-slate-800 text-gray-600 dark:text-slate-300"
          />
        </div>
      </div>

      {/* Children Tree */}
      {hasChildren && (expanded || searchTerm) && (
        <div className="relative">
          {/* Vertical connecting line indicator */}
          <div 
            className="absolute top-0 bottom-4 w-px bg-gray-100 dark:bg-slate-800" 
            style={{ left: `${(node.level * 16) + 12}px` }} 
          />
          <div className="mt-1 space-y-1">
            {node.children.map((child) => (
              <CategoryTreeNode 
                key={child.id} 
                node={child} 
                onAddChild={onAddChild} 
                onEdit={onEdit}
                searchTerm={searchTerm}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default CategoryTreeNode;
