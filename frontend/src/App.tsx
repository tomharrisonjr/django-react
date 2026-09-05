import { useEffect, useState } from "react";
import { api, type Task } from "./api";
import "./App.css";

function App() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [title, setTitle] = useState("");
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api
      .list()
      .then((data) => setTasks(data.results))
      .catch((err) => setError(String(err)));
  }, []);

  async function handleAdd(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) return;
    try {
      const task = await api.create(title.trim());
      setTasks((prev) => [task, ...prev]);
      setTitle("");
    } catch (err) {
      setError(String(err));
    }
  }

  async function handleToggle(task: Task) {
    try {
      const updated = await api.toggle(task);
      setTasks((prev) => prev.map((t) => (t.id === updated.id ? updated : t)));
    } catch (err) {
      setError(String(err));
    }
  }

  async function handleRemove(id: number) {
    try {
      await api.remove(id);
      setTasks((prev) => prev.filter((t) => t.id !== id));
    } catch (err) {
      setError(String(err));
    }
  }

  return (
    <div className="app">
      <h1>Tasks</h1>
      {error && <p className="error">{error}</p>}
      <form onSubmit={handleAdd}>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="New task"
        />
        <button type="submit">Add</button>
      </form>
      <ul>
        {tasks.map((task) => (
          <li key={task.id} className={task.done ? "done" : ""}>
            <label>
              <input
                type="checkbox"
                checked={task.done}
                onChange={() => handleToggle(task)}
              />
              {task.title}
            </label>
            <button onClick={() => handleRemove(task.id)}>Delete</button>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
