'use client'

import { Wifi, Settings } from 'lucide-react'
import { useState } from 'react'

interface DashboardHeaderProps {
  ipAddress?: string
  port?: string
  onSettingsClick?: () => void
}

export function DashboardHeader({
  ipAddress = '192.168.1.150',
  port = '8000',
  onSettingsClick,
}: DashboardHeaderProps) {
  const [isConnected] = useState(true)

  return (
    <div className="glass-dark rounded-3xl p-6 mb-6 border-slate-700/30">
      <div className="flex items-center justify-between">
        <div className="flex-1">
          <h1 className="text-3xl font-bold bg-gradient-to-r from-cyan-400 to-blue-400 bg-clip-text text-transparent mb-2">
            Laptop Remote
          </h1>
          <div className="flex items-center gap-2">
            <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-emerald-500 animate-pulse' : 'bg-rose-500'}`} />
            <span className="text-sm text-slate-400">
              {isConnected ? 'Connected' : 'Disconnected'}: {ipAddress}:{port}
            </span>
          </div>
        </div>
        <button
          onClick={onSettingsClick}
          className="p-3 rounded-xl hover:bg-slate-700/50 transition-all text-slate-400 hover:text-slate-200"
          aria-label="Settings"
        >
          <Settings size={24} />
        </button>
      </div>
    </div>
  )
}
