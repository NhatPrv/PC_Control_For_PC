'use client'

import { useState } from 'react'
import { Cpu, Battery, Volume2, Sun, Power, RotateCcw, Moon, Zap } from 'lucide-react'
import { DashboardHeader } from '@/components/dashboard-header'
import { DeviceMonitorCard } from '@/components/device-monitor-card'
import { ControlSlider } from '@/components/control-slider'
import { PowerActionButton } from '@/components/power-action-button'

export default function Page() {
  const [cpuUsage, setCpuUsage] = useState(24)
  const [ramUsage, setRamUsage] = useState(58)
  const [brightness, setBrightness] = useState(70)
  const [volume, setVolume] = useState(45)
  const [loadingPower, setLoadingPower] = useState<string | null>(null)

  const handlePowerAction = (action: string) => {
    setLoadingPower(action)
    // Simulate API call
    setTimeout(() => setLoadingPower(null), 2000)
  }

  const handleSettingsClick = () => {
    console.log('Settings clicked')
  }

  return (
    <main className="min-h-screen bg-slate-950 text-slate-100 p-4 md:p-6">
      <div className="max-w-2xl mx-auto">
        {/* Header */}
        <DashboardHeader onSettingsClick={handleSettingsClick} />

        {/* System Monitor Cards */}
        <div className="grid grid-cols-3 gap-4 mb-6">
          <DeviceMonitorCard
            title="CPU Usage"
            value={cpuUsage}
            unit="cores"
            icon={<Cpu size={16} />}
            color="cyan"
          />
          <DeviceMonitorCard
            title="RAM Usage"
            value={ramUsage}
            unit="GB"
            icon={<Battery size={16} />}
            color="slate"
          />
          <DeviceMonitorCard
            title="Battery"
            value={85}
            unit="Charging"
            icon={<Zap size={16} />}
            color="emerald"
          />
        </div>

        {/* Control Sliders */}
        <div className="space-y-4 mb-6">
          <ControlSlider
            label="Screen Brightness"
            initialValue={brightness}
            onValueChange={setBrightness}
          />
          <div className="flex gap-4">
            <div className="flex-1">
              <ControlSlider
                label="Volume"
                initialValue={volume}
                onValueChange={setVolume}
                showToggle
              />
            </div>
          </div>
        </div>

        {/* Power Actions */}
        <div className="grid grid-cols-2 gap-4">
          <PowerActionButton
            label="Shutdown"
            icon={<Power size={28} />}
            color="rose"
            onClick={() => handlePowerAction('shutdown')}
            loading={loadingPower === 'shutdown'}
          />
          <PowerActionButton
            label="Restart"
            icon={<RotateCcw size={28} />}
            color="amber"
            onClick={() => handlePowerAction('restart')}
            loading={loadingPower === 'restart'}
          />
          <PowerActionButton
            label="Sleep"
            icon={<Moon size={28} />}
            color="purple"
            onClick={() => handlePowerAction('sleep')}
            loading={loadingPower === 'sleep'}
          />
          <PowerActionButton
            label="Wake-on-LAN"
            icon={<Zap size={28} />}
            color="emerald"
            onClick={() => handlePowerAction('wake')}
            loading={loadingPower === 'wake'}
          />
        </div>
      </div>
    </main>
  )
}
