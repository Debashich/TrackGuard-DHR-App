// Ambient declarations for TypeScript language servers when Deno LS is inactive.

declare namespace Deno {
  export interface Env {
    get(key: string): string | undefined;
    set(key: string, value: string): void;
    has(key: string): boolean;
    delete(key: string): void;
    toObject(): Record<string, string>;
  }

  export const env: Env;

  export function serve(
    handler: (req: Request) => Promise<Response> | Response,
  ): void;
}

declare module "@supabase/supabase-js" {
  export function createClient(
    supabaseUrl: string,
    supabaseKey: string,
    options?: any,
  ): any;
  export type SupabaseClient = any;
  export type User = any;
}

declare module "@supabase/functions-js/edge-runtime.d.ts" {}

