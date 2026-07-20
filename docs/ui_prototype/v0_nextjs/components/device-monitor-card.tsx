'use client'

import { CircularProgressbar, buildStyles } from 'react-circular-progressbar'
import 'react-circular-progressbar/dist/styles.css'

interface DeviceMonitorCardProps {
  title: string
  value: number
  unit: string
  icon: React.ReactNode
  color: 'cyan' | 'slate' | 'emerald'
}

const colorMap = {
  cyan: {
    trail: 'rgba(6, 182, 212, 0.2)',
    path: '#06b6d4',
    glow: 'glow-cyan',
  },
  slate: {
    trail: 'rgba(148, 163, 184, 0.2)',
    path: '#94a3b8',
    glow: 'glow-cyan',
  },
  emerald: {
    trail: 'rgba(16, 185, 129, 0.2)',
    path: '#10b981',
    glow: 'glow-emerald',
  },
}

export function DeviceMonitorCard({
  title,
  value,
  unit,
  icon,
  color,
}: DeviceMonitorCardProps) {
  const colorScheme = colorMap[color]

  return (
    <div className={`glass rounded-2xl p-6 ${colorScheme.glow}`}>
      <div className="flex flex-col items-center gap-4">
        <div className="text-slate-400 text-sm font-medium">{title}</div>
        <div style={{ width: 120, height: 120 }}>
          <CircularProgressbar
            value={value}
            text={`${value}%`}
            styles={buildStyles({
              rotation: 0.25,
              strokeLinecap: 'round',
              textSize: '24px',
              pathTransitionDuration: 0.5,
              pathColor: colorScheme.path,
              textColor: '#f1f5f9',
              trailColor: colorScheme.trail,
              backgroundColor: 'transparent',
            })}
          />
        </div>
        <div className="text-slate-400 text-xs flex items-center gap-1">
          {icon}
          <span>{unit}</span>
        </div>
      </div>
    </div>
  )
}
