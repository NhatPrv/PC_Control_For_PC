'use client'

import { useState } from 'react'

interface ControlSliderProps {
  label: string
  initialValue: number
  onValueChange?: (value: number) => void
  showToggle?: boolean
  onToggle?: (enabled: boolean) => void
}

export function ControlSlider({
  label,
  initialValue,
  onValueChange,
  showToggle = false,
  onToggle,
}: ControlSliderProps) {
  const [value, setValue] = useState(initialValue)
  const [toggled, setToggled] = useState(true)

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = parseInt(e.target.value)
    setValue(newValue)
    onValueChange?.(newValue)
  }

  const handleToggle = () => {
    const newToggled = !toggled
    setToggled(newToggled)
    onToggle?.(newToggled)
  }

  return (
    <div className="glass rounded-2xl p-6">
      <div className="flex items-center justify-between mb-4">
        <span className="text-slate-200 font-medium">{label}</span>
        <div className="text-cyan-400 font-semibold text-lg">{value}%</div>
      </div>

      <input
        type="range"
        min="0"
        max="100"
        value={value}
        onChange={handleChange}
        className="w-full h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer slider"
        style={{
          background: `linear-gradient(to right, #06b6d4 0%, #06b6d4 ${value}%, #334155 ${value}%, #334155 100%)`,
        }}
      />

      {showToggle && (
        <button
          onClick={handleToggle}
          className={`mt-4 w-full px-4 py-2 rounded-lg font-medium transition-all ${
            toggled
              ? 'bg-cyan-500/20 text-cyan-400 border border-cyan-500/40'
              : 'bg-slate-700/20 text-slate-500 border border-slate-700/40'
          }`}
        >
          {toggled ? 'Muted: OFF' : 'Muted: ON'}
        </button>
      )}

      <style jsx>{`
        .slider::-webkit-slider-thumb {
          appearance: none;
          width: 20px;
          height: 20px;
          border-radius: 50%;
          background: #06b6d4;
          cursor: pointer;
          box-shadow: 0 0 12px rgba(6, 182, 212, 0.6);
          border: 2px solid rgba(241, 245, 249, 0.3);
        }

        .slider::-moz-range-thumb {
          width: 20px;
          height: 20px;
          border-radius: 50%;
          background: #06b6d4;
          cursor: pointer;
          box-shadow: 0 0 12px rgba(6, 182, 212, 0.6);
          border: 2px solid rgba(241, 245, 249, 0.3);
        }

        .slider::-webkit-slider-runnable-track {
          background: transparent;
          height: 8px;
          border-radius: 4px;
        }

        .slider::-moz-range-track {
          background: transparent;
          border: none;
        }
      `}</style>
    </div>
  )
}
