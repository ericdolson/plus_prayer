// Thin typed wrappers over the admin connector's named operations.

import { DataConnect } from "firebase-admin/data-connect";

export async function query<T>(db: DataConnect, name: string, variables?: object): Promise<T> {
  const res = variables === undefined
    ? await db.executeQuery<T>(name)
    : await db.executeQuery<T, object>(name, variables);
  return res.data;
}

export async function mutate<T = unknown>(db: DataConnect, name: string, variables?: object): Promise<T> {
  const res = variables === undefined
    ? await db.executeMutation<T>(name)
    : await db.executeMutation<T, object>(name, variables);
  return res.data;
}

/** True if a SQL Connect error carries one of our @check messages. */
export function hasCheck(err: unknown, message: string): boolean {
  return err instanceof Error && err.message.includes(message);
}
