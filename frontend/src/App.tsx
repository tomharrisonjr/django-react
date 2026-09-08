import { useEffect, useState } from "react";
import { AlertCircle, ListTodo, Trash2 } from "lucide-react";
import { api, getErrorMessage, type Task } from "./api";
import { Alert, AlertDescription, AlertTitle } from "./components/ui/alert";
import { Badge } from "./components/ui/badge";
import { Button } from "./components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "./components/ui/card";
import { Checkbox } from "./components/ui/checkbox";
import { Input } from "./components/ui/input";
import { APP_VERSION } from "./lib/version";

function App() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [title, setTitle] = useState("");
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api
      .list()
      .then((data) => setTasks(data.results))
      .catch((err) => setError(getErrorMessage(err)));
  }, []);

  async function handleAdd(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) return;
    try {
      const task = await api.create(title.trim());
      setTasks((prev) => [task, ...prev]);
      setTitle("");
      setError(null);
    } catch (err) {
      setError(getErrorMessage(err));
    }
  }

  async function handleToggle(task: Task) {
    try {
      const updated = await api.toggle(task);
      setTasks((prev) => prev.map((t) => (t.id === updated.id ? updated : t)));
      setError(null);
    } catch (err) {
      setError(getErrorMessage(err));
    }
  }

  async function handleRemove(id: number) {
    try {
      await api.remove(id);
      setTasks((prev) => prev.filter((t) => t.id !== id));
      setError(null);
    } catch (err) {
      setError(getErrorMessage(err));
    }
  }

  return (
    <div className="flex min-h-svh flex-col bg-background">
      <header className="border-b">
        <div className="mx-auto flex max-w-2xl items-center gap-2 px-4 py-4">
          <ListTodo className="size-6 text-primary" />
          <h1 className="text-xl font-semibold">Tasks</h1>
        </div>
      </header>

      <main className="mx-auto w-full max-w-2xl flex-1 px-4 py-8">
        <Card>
          <CardHeader>
            <CardTitle>Your tasks</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col gap-4">
            {error && (
              <Alert variant="destructive">
                <AlertCircle />
                <AlertTitle>Something went wrong</AlertTitle>
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}

            <form onSubmit={handleAdd} className="flex gap-2">
              <Input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="New task"
              />
              <Button type="submit">Add</Button>
            </form>

            {tasks.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                {error ? "Unable to load tasks." : "No tasks yet — add one above."}
              </p>
            ) : (
              <ul className="flex flex-col divide-y divide-border">
                {tasks.map((task) => (
                  <li
                    key={task.id}
                    className="flex items-center justify-between gap-2 py-2"
                  >
                    <label className="flex flex-1 items-center gap-2 cursor-pointer">
                      <Checkbox
                        checked={task.done}
                        onCheckedChange={() => handleToggle(task)}
                      />
                      <span
                        className={
                          task.done ? "text-muted-foreground line-through" : ""
                        }
                      >
                        {task.title}
                      </span>
                    </label>
                    <Button
                      variant="ghost"
                      size="icon-sm"
                      onClick={() => handleRemove(task.id)}
                      aria-label={`Delete ${task.title}`}
                    >
                      <Trash2 className="size-4" />
                    </Button>
                  </li>
                ))}
              </ul>
            )}
          </CardContent>
        </Card>
      </main>

      <footer className="border-t py-4">
        <div className="mx-auto flex max-w-2xl items-center justify-center gap-2 px-4 text-sm text-muted-foreground">
          <span>Task Manager</span>
          <Badge variant="secondary">v{APP_VERSION}</Badge>
        </div>
      </footer>
    </div>
  );
}

export default App;
