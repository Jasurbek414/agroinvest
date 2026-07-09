import React, { useState, useRef, useEffect } from 'react';

const OTPInput = ({ length = 6, onComplete, error, disabled }) => {
  const [otp, setOtp] = useState(new Array(length).fill(''));
  const inputsRef = useRef([]);
  const firedForRef = useRef(null);

  useEffect(() => {
    if (inputsRef.current[0]) {
      inputsRef.current[0].focus();
    }
  }, []);

  // A failed verification (wrong/expired code, network hiccup) previously left
  // the boxes full with no way to retry other than manually backspacing every
  // digit - any correction attempt re-fired onComplete with a half-old,
  // half-new code. Clear and refocus so the next attempt starts clean.
  useEffect(() => {
    if (error) {
      setOtp(new Array(length).fill(''));
      firedForRef.current = null;
      inputsRef.current[0]?.focus();
    }
  }, [error, length]);

  const handleChange = (element, index) => {
    if (disabled) return;
    const value = element.value;
    if (isNaN(value)) return;

    const newOtp = [...otp];
    newOtp[index] = value.substring(value.length - 1);
    setOtp(newOtp);

    if (value && index < length - 1 && inputsRef.current[index + 1]) {
      inputsRef.current[index + 1].focus();
    }

    const otpString = newOtp.join('');
    // Only fire once per distinct completed code - editing a single digit
    // inside an already-full set of boxes (e.g. correcting a typo) shouldn't
    // re-submit until the whole code is complete and different again.
    if (otpString.length === length && firedForRef.current !== otpString) {
      firedForRef.current = otpString;
      onComplete(otpString);
    } else if (otpString.length < length) {
      firedForRef.current = null;
    }
  };

  const handleKeyDown = (e, index) => {
    if (disabled) return;
    if (e.key === 'Backspace') {
      const newOtp = [...otp];
      newOtp[index] = '';
      setOtp(newOtp);
      firedForRef.current = null;

      if (index > 0 && inputsRef.current[index - 1]) {
        inputsRef.current[index - 1].focus();
      }
    }
  };

  const handlePaste = (e) => {
    if (disabled) return;
    e.preventDefault();
    const pasteData = e.clipboardData.getData('text').trim();
    if (pasteData.length !== length || isNaN(pasteData)) return;

    const newOtp = pasteData.split('');
    setOtp(newOtp);
    if (firedForRef.current !== pasteData) {
      firedForRef.current = pasteData;
      onComplete(pasteData);
    }
  };

  return (
    <div className="flex flex-col items-center gap-2">
      <div className="flex justify-center gap-2" onPaste={handlePaste}>
        {otp.map((data, index) => (
          <input
            key={index}
            type="text"
            inputMode="numeric"
            maxLength={1}
            disabled={disabled}
            ref={(el) => (inputsRef.current[index] = el)}
            value={data}
            onChange={(e) => handleChange(e.target, index)}
            onKeyDown={(e) => handleKeyDown(e, index)}
            className={`w-12 h-12 text-center text-xl font-semibold border-2 rounded-lg outline-none transition disabled:opacity-50 dark:bg-slate-900 dark:text-slate-100 ${
              error
                ? 'border-red-400 dark:border-red-500'
                : 'border-gray-300 dark:border-slate-600 focus:border-primary-500'
            }`}
          />
        ))}
      </div>
    </div>
  );
};

export default OTPInput;
