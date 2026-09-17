import React from 'react';
import { ShieldAlert, Info } from 'lucide-react';

interface ReportSectionProps {
  reportCount: number;
  reportReasons: string[];
  adminNote: string;
}

/** Hiển thị thông tin phân tích vi phạm từ hệ thống AI */
export const ReportSection: React.FC<ReportSectionProps> = ({
  reportCount,
  reportReasons,
  adminNote,
}) => {
  if (reportCount === 0) return null;

  return (
    <div className="rd-report-section ai-system-report">
      <div className="rd-report-header">
        <div className="rd-report-title">
          <span>VI PHẠM</span>
        </div>
        <div className="ai-status-badge">
          <ShieldAlert size={14} />
        </div>
      </div>

      <div className="rd-report-body">
        <div className="rd-report-reasons">
          <span className="rd-report-label">DẤU HIỆU VI PHẠM</span>
          <div className="rd-reason-tags">
            {reportReasons.map((reason, idx) => (
              <span key={idx} className="rd-reason-tag ai-tag">
                {reason}
              </span>
            ))}
          </div>
        </div>

        {adminNote && (
          <div className="rd-admin-note">
            <span className="rd-report-label">KIẾN NGHỊ TỪ HỆ THỐNG</span>
            <div className="rd-note-box ai-note-box">
              <div className="ai-note-header">
                <Info size={14} />
                <span>Ghi chú phân tích</span>
              </div>
              <p>{adminNote}</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
