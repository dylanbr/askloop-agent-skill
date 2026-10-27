#!/usr/bin/env node
import { readFileSync, writeFileSync, existsSync } from "node:fs";

const FILE = new URL("./todos.json", import.meta.url);
const load = () => (existsSync(FILE) ? JSON.parse(readFileSync(FILE, "utf8")) : []);
const save = (todos) => writeFileSync(FILE, JSON.stringify(todos, null, 2) + "\n");

const [cmd, ...rest] = process.argv.slice(2);
const todos = load();

if (cmd === "add") {
  todos.push({ id: todos.length + 1, text: rest.join(" "), done: false });
  save(todos);
} else if (cmd === "done") {
  const todo = todos.find((t) => t.id === Number(rest[0]));
  if (todo) todo.done = true;
  save(todos);
} else {
  for (const t of todos) console.log(`${t.done ? "[x]" : "[ ]"} ${t.id}. ${t.text}`);
}
