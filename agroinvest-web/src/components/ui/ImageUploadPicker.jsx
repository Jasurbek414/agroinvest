import React, { useRef, useState } from 'react';
import { Plus, X, Loader2, FileText } from 'lucide-react';
import { uploadFile } from '../../api/uploads.api';

// Reusable multi-image picker: uploads each selected file to real object storage and
// reports the resulting public URLs back to the parent form. Replaces the previous
// pattern of a free-text "media URL" field defaulting to a hardcoded mock photo.
const ImageUploadPicker = ({ category, urls, onChange, maxImages = 5, accept = 'image/jpeg,image/png,image/webp' }) => {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState(null);
  const inputRef = useRef(null);

  const handleFileChange = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file) return;

    setUploading(true);
    setError(null);
    try {
      const res = await uploadFile(file, category);
      onChange([...urls, res.data.url]);
    } catch (err) {
      setError(err.error?.message || 'Faylni yuklashda xatolik yuz berdi');
    } finally {
      setUploading(false);
    }
  };

  const removeAt = (index) => {
    onChange(urls.filter((_, i) => i !== index));
  };

  return (
    <div>
      <div className="flex flex-wrap gap-3">
        {urls.map((url, i) => (
          <div key={url} className="relative w-20 h-20">
            {url.toLowerCase().endsWith('.pdf') ? (
              <a
                href={url}
                target="_blank"
                rel="noreferrer"
                className="w-20 h-20 flex flex-col items-center justify-center gap-1 rounded-xl border border-gray-100 bg-gray-50 text-gray-500"
              >
                <FileText size={20} />
                <span className="text-[9px] font-bold">PDF</span>
              </a>
            ) : (
              <img src={url} alt={`Yuklangan fayl ${i + 1}`} className="w-20 h-20 object-cover rounded-xl border border-gray-100" />
            )}
            <button
              type="button"
              onClick={() => removeAt(i)}
              aria-label="Rasmni olib tashlash"
              className="absolute -top-2 -right-2 w-5 h-5 bg-red-600 text-white rounded-full flex items-center justify-center"
            >
              <X size={12} />
            </button>
          </div>
        ))}
        {urls.length < maxImages && (
          <button
            type="button"
            onClick={() => inputRef.current?.click()}
            disabled={uploading}
            className="w-20 h-20 border-2 border-dashed border-gray-200 hover:border-green-400 rounded-xl flex items-center justify-center text-gray-400 transition"
          >
            {uploading ? <Loader2 size={20} className="animate-spin" /> : <Plus size={20} />}
          </button>
        )}
      </div>
      <input ref={inputRef} type="file" accept={accept} className="hidden" onChange={handleFileChange} />
      {error && <p className="text-xs text-red-600 mt-2">{error}</p>}
    </div>
  );
};

export default ImageUploadPicker;
