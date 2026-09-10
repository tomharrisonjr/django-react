export interface Task {
  id: number;
  title: string;
  done: boolean;
  created_at: string;
}

interface TaskList {
  count: number;
  next: string | null;
  previous: string | null;
  results: Task[];
}

const API_BASE = import.meta.env.VITE_API_BASE ?? "http://127.0.0.1:8000/api";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...init,
  });
  if (!res.ok) {
    throw new Error(`API error ${res.status}: ${await res.text()}`);
  }
  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

export function getErrorMessage(err: unknown): string {
  if (err instanceof TypeError) {
    return `Can't reach the server at ${API_BASE}. Is the backend running?`;
  }
  if (err instanceof Error) {
    return err.message;
  }
  return String(err);
}

export const api = {
  list: () => request<TaskList>("/tasks/"),
  create: (title: string) =>
    request<Task>("/tasks/", {
      method: "POST",
      body: JSON.stringify({ title }),
    }),
  toggle: (task: Pick<Task, "id" | "done">) =>
    request<Task>(`/tasks/${task.id}/`, {
      method: "PATCH",
      body: JSON.stringify({ done: !task.done }),
    }),
  remove: (id: number) => request<void>(`/tasks/${id}/`, { method: "DELETE" }),
};
