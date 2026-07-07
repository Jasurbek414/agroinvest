import { useEffect, useState } from 'react';

// Delays reflecting a fast-changing value (e.g. a search input) until it has
// stopped changing for `delayMs` - used so admin search inputs don't fire an
// API request on every keystroke.
export function useDebounce(value, delayMs = 300) {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delayMs);
    return () => clearTimeout(timer);
  }, [value, delayMs]);

  return debounced;
}
