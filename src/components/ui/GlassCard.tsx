/**
 * PratibimbAI Glassmorphic UI Components
 * Premium glass-style UI with backdrop blur
 */

import React from 'react';
import { cn } from '../../utils/cn';

interface GlassCardProps {
  children: React.ReactNode;
  className?: string;
  blur?: 'sm' | 'md' | 'lg' | 'xl';
  opacity?: number;
  border?: boolean;
  glow?: boolean;
  onClick?: () => void;
}

export const GlassCard: React.FC<GlassCardProps> = ({
  children,
  className = '',
  blur = 'lg',
  opacity = 0.15,
  border = true,
  glow = false,
  onClick,
}) => {
  const blurMap = {
    sm: 'backdrop-blur-sm',
    md: 'backdrop-blur-md',
    lg: 'backdrop-blur-lg',
    xl: 'backdrop-blur-xl',
  };

  return (
    <div
      onClick={onClick}
      className={cn(
        'rounded-2xl',
        blurMap[blur],
        border && 'border border-white/10',
        glow && 'shadow-lg shadow-indigo-500/20',
        onClick && 'cursor-pointer hover:bg-white/20 transition-colors',
        className
      )}
      style={{
        backgroundColor: `rgba(30, 30, 50, ${opacity})`,
      }}
    >
      {children}
    </div>
  );
};

interface GlassButtonProps {
  children: React.ReactNode;
  onClick?: () => void;
  className?: string;
  variant?: 'default' | 'primary' | 'success' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  icon?: React.ReactNode;
}

export const GlassButton: React.FC<GlassButtonProps> = ({
  children,
  onClick,
  className = '',
  variant = 'default',
  size = 'md',
  disabled = false,
  icon,
}) => {
  const variants = {
    default: 'bg-white/10 hover:bg-white/20 text-white border-white/20',
    primary: 'bg-indigo-500/30 hover:bg-indigo-500/50 text-indigo-100 border-indigo-400/30',
    success: 'bg-emerald-500/30 hover:bg-emerald-500/50 text-emerald-100 border-emerald-400/30',
    danger: 'bg-red-500/30 hover:bg-red-500/50 text-red-100 border-red-400/30',
  };

  const sizes = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  };

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={cn(
        'rounded-xl border backdrop-blur-md transition-all duration-200',
        'flex items-center justify-center gap-2',
        'disabled:opacity-50 disabled:cursor-not-allowed',
        'active:scale-95',
        variants[variant],
        sizes[size],
        className
      )}
    >
      {icon && <span className="w-5 h-5">{icon}</span>}
      {children}
    </button>
  );
};

interface GlassInputProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  className?: string;
  icon?: React.ReactNode;
}

export const GlassInput: React.FC<GlassInputProps> = ({
  value,
  onChange,
  placeholder = '',
  className = '',
  icon,
}) => {
  return (
    <div className={cn('relative', className)}>
      {icon && (
        <div className="absolute left-4 top-1/2 -translate-y-1/2 text-white/50">
          {icon}
        </div>
      )}
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className={cn(
          'w-full rounded-xl border border-white/20 bg-white/10 backdrop-blur-lg',
          'px-4 py-3 text-white placeholder-white/40',
          'focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500/50',
          'transition-all duration-200',
          icon && 'pl-12'
        )}
      />
    </div>
  );
};

interface GlassSidebarProps {
  children: React.ReactNode;
  isOpen: boolean;
  onClose?: () => void;
  side?: 'left' | 'right';
  width?: string;
}

export const GlassSidebar: React.FC<GlassSidebarProps> = ({
  children,
  isOpen,
  onClose,
  side = 'left',
  width = 'w-80',
}) => {
  return (
    <>
      {/* Backdrop */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/30 backdrop-blur-sm z-40 md:hidden"
          onClick={onClose}
        />
      )}
      
      {/* Sidebar */}
      <div
        className={cn(
          'fixed top-0 h-full z-50 transition-transform duration-300',
          width,
          side === 'left' ? 'left-0' : 'right-0',
          side === 'left'
            ? isOpen ? 'translate-x-0' : '-translate-x-full'
            : isOpen ? 'translate-x-0' : 'translate-x-full',
          'bg-gradient-to-b from-slate-900/90 to-slate-950/95',
          'backdrop-blur-xl border-r border-white/10'
        )}
      >
        {children}
      </div>
    </>
  );
};

export default GlassCard;
