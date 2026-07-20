'use client'

interface PowerActionButtonProps {
  label: string
  icon: React.ReactNode
  color: 'rose' | 'amber' | 'purple' | 'emerald'
  onClick?: () => void
  loading?: boolean
}

const colorMap = {
  rose: {
    bg: 'bg-rose-500/10',
    border: 'border-rose-500/30',
    text: 'text-rose-400',
    hover: 'hover:bg-rose-500/20 hover:border-rose-500/50 hover:shadow-lg hover:shadow-rose-500/20',
    icon: 'text-rose-500',
    glow: 'glow-rose',
  },
  amber: {
    bg: 'bg-amber-500/10',
    border: 'border-amber-500/30',
    text: 'text-amber-400',
    hover: 'hover:bg-amber-500/20 hover:border-amber-500/50 hover:shadow-lg hover:shadow-amber-500/20',
    icon: 'text-amber-500',
    glow: 'glow-amber',
  },
  purple: {
    bg: 'bg-purple-500/10',
    border: 'border-purple-500/30',
    text: 'text-purple-400',
    hover: 'hover:bg-purple-500/20 hover:border-purple-500/50 hover:shadow-lg hover:shadow-purple-500/20',
    icon: 'text-purple-500',
    glow: 'glow-purple',
  },
  emerald: {
    bg: 'bg-emerald-500/10',
    border: 'border-emerald-500/30',
    text: 'text-emerald-400',
    hover: 'hover:bg-emerald-500/20 hover:border-emerald-500/50 hover:shadow-lg hover:shadow-emerald-500/20',
    icon: 'text-emerald-500',
    glow: 'glow-emerald',
  },
}

export function PowerActionButton({
  label,
  icon,
  color,
  onClick,
  loading = false,
}: PowerActionButtonProps) {
  const colors = colorMap[color]

  return (
    <button
      onClick={onClick}
      disabled={loading}
      className={`glass rounded-2xl p-6 border transition-all duration-200 flex flex-col items-center gap-3 ${colors.bg} ${colors.border} ${colors.hover} ${!loading ? '' : 'opacity-50 cursor-not-allowed'}`}
    >
      <div className={`text-3xl transition-transform duration-200 ${colors.icon} ${!loading ? 'group-hover:scale-110' : ''}`}>
        {icon}
      </div>
      <span className={`font-semibold text-sm ${colors.text}`}>{label}</span>
      {loading && (
        <div className="mt-1 h-1 w-1 rounded-full bg-current animate-pulse" />
      )}
    </button>
  )
}
