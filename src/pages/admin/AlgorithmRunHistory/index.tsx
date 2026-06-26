import React, { useEffect, useState } from 'react';
import { Bell, RefreshCw } from 'lucide-react';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import {
  algorithmPipelineAPI,
  formatPipelineDateTime,
  formatPipelineDuration,
  type PipelineHistoryItem,
} from '../../../services/algorithmPipelineAPI';
import './AlgorithmRunHistory.css';

const ALGORITHM_LABELS: Record<string, string> = {
  review_filter: 'Phân loại đánh giá',
  two_tower_retrieval: 'Gợi ý địa điểm',
  hybrid_recommender: 'Gợi ý địa điểm',
};

const getAlgorithmLabel = (name?: string): string => {
  if (!name) return 'Thuật toán';
  return ALGORITHM_LABELS[name] ?? name;
};

const getReviewFilterMessage = (
  processed: number,
  total: number,
): string => `Đã xử lý ${processed}/${total} đánh giá đã duyệt đang chờ xử lý`;

const getDetailText = (row: PipelineHistoryItem): string => {
  if (row.error) return row.error;

  const details = row.details ?? {};
  const message = details.result_message;

  if (row.algorithm_name === 'review_filter') {
    return getReviewFilterMessage(row.contents_processed, row.total_reviews);
  }

  if (typeof message === 'string') {
    const processedMatch = message.match(
      /Processed\s+(\d+)\/(\d+)\s+approved pending reviews/i,
    );
    if (processedMatch) {
      return getReviewFilterMessage(
        Number(processedMatch[1]),
        Number(processedMatch[2]),
      );
    }
    return message;
  }

  return typeof details.value === 'string'
    ? details.value
    : 'Đã ghi nhận lịch sử chạy thuật toán';
};

export const AlgorithmRunHistory: React.FC = () => {
  const [rows, setRows] = useState<PipelineHistoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadHistory = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await algorithmPipelineAPI.getHistory(50);
      setRows(response.history);
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Không thể tải lịch sử chạy thuật toán';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadHistory();
  }, []);

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
          <button
            className="icon-btn"
            onClick={loadHistory}
            disabled={loading}
            title="Tải lại"
            type="button"
          >
            <RefreshCw size={18} className={loading ? 'arh-spin' : undefined} />
          </button>
          <button className="icon-btn" type="button">
            <Bell size={20} />
          </button>
          <AdminHeaderProfile />
        </div>
      </header>

      <div className="page-content arh-content">
        <div className="arh-card">
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
                {loading && (
                  <tr>
                    <td colSpan={5} className="arh-state">
                      Đang tải lịch sử...
                    </td>
                  </tr>
                )}
                {!loading && error && (
                  <tr>
                    <td colSpan={5} className="arh-state arh-err-text">
                      {error}
                    </td>
                  </tr>
                )}
                {!loading && !error && rows.length === 0 && (
                  <tr>
                    <td colSpan={5} className="arh-state">
                      Chưa có lịch sử chạy thuật toán.
                    </td>
                  </tr>
                )}
                {!loading &&
                  !error &&
                  rows.map((row) => {
                    const status = row.success ? 'done' : 'error';
                    return (
                      <tr key={row.run_id}>
                        <td className="arh-fw500">
                          {getAlgorithmLabel(row.algorithm_name)}
                        </td>
                        <td className="arh-muted">
                          {formatPipelineDateTime(
                            row.started_at || row.created_at || '',
                          )}
                        </td>
                        <td className="arh-muted">
                          {formatPipelineDuration(row.duration_seconds || 0)}
                        </td>
                        <td>
                          <span className={`arh-badge arh-badge--${status}`}>
                            <span className="arh-badge__dot" />
                            {status === 'done' ? 'Hoàn thành' : 'Thất bại'}
                          </span>
                        </td>
                        <td
                          className={
                            status === 'error' ? 'arh-err-text' : 'arh-muted'
                          }
                        >
                          {getDetailText(row)}
                        </td>
                      </tr>
                    );
                  })}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};
