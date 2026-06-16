import React from 'react';
import { Bell } from 'lucide-react';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import './AlgorithmRunHistory.css';

const HISTORY_ROWS = [
  {
    algo: 'Phân loại đánh giá',
    date: '22/10/2023 14:32',
    duration: '1h 30 phút',
    status: 'done' as const,
    result: 'Đã phân loại 350 đánh giá mới',
  },
  {
    algo: 'Gợi ý địa điểm',
    date: '21/10/2023 02:00',
    duration: '12m 40s',
    status: 'done' as const,
    result: 'Cập nhật 45 gợi ý cho người dùng',
  },
  {
    algo: 'Phát hiện xung đột',
    date: '20/10/2023 02:00',
    duration: '2m 15s',
    status: 'error' as const,
    result: 'Lỗi kết nối cơ sở dữ liệu (7/min/số)',
  },
  {
    algo: 'Gợi ý địa điểm',
    date: '19/10/2023 02:00',
    duration: '18m 20s',
    status: 'done' as const,
    result: 'Xử lý 1,200 địa điểm cho duyệt',
  },
];

export const AlgorithmRunHistory: React.FC = () => {
  return (
    <div className="page-container arh-page">
      <header className="page-header">
        <div className="header-titles">
          <h1 className="page-title">Lịch sử chạy thuật toán</h1>
          <div className="breadcrumb">
            <span className="text-muted">Cài đặt</span>
            {' / '}
            <span className="active-bread">Lịch sử chạy thuật toán</span>
          </div>
        </div>
        <div className="header-actions">
          <button className="icon-btn"><Bell size={20} /></button>
          <AdminHeaderProfile />
        </div>
      </header>

      <div className="page-content arh-content">
        <div className="arh-card">
          <div className="arh-card__header">
            <span className="arh-card__dot" />
            <span className="arh-card__title">Lịch sử chạy thuật toán</span>
          </div>
          <div className="arh-table-wrap">
            <table className="arh-table">
              <thead>
                <tr>
                  <th>Thuật toán</th>
                  <th>Ngày chạy</th>
                  <th>Thời gian</th>
                  <th>Trạng thái</th>
                  <th>Kết quả chi tiết</th>
                </tr>
              </thead>
              <tbody>
                {HISTORY_ROWS.map((row, idx) => (
                  <tr key={idx}>
                    <td className="arh-fw500">{row.algo}</td>
                    <td className="arh-muted">{row.date}</td>
                    <td className="arh-muted">{row.duration}</td>
                    <td>
                      <span className={`arh-badge arh-badge--${row.status}`}>
                        <span className="arh-badge__dot" />
                        {row.status === 'done' ? 'Hoàn thành' : 'Thất bại'}
                      </span>
                    </td>
                    <td className={row.status === 'error' ? 'arh-err-text' : 'arh-muted'}>
                      {row.result}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};
