import React from 'react';

export default function PlanBadge({ plan }) {
  if (plan === 'pro') {
    return (
      <span title="Plan Pro" className="inline-flex items-center">
        <span className="text-yellow-500 text-lg ml-1" role="img" aria-label="Pro">
          👑
        </span>
      </span>
    );
  }
  if (plan === 'empresa' || plan === 'enterprise') {
    return (
      <span title="Plan Empresa" className="inline-flex items-center ml-1 gap-0.5">
        <span className="bg-blue-600 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full leading-none">
          PRO+
        </span>
        <span role="img" aria-label="Empresa">
          🏢
        </span>
      </span>
    );
  }
  return null;
}
