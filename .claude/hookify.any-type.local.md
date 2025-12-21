---
name: block-typescript-any
enabled: true
event: file
action: block
conditions:
  - field: content
    operator: regex_match
    pattern: ":\\s*any\\b"
  - field: file_path
    operator: regex_match
    pattern: \.(ts|tsx)$
---

**TypeScript `any` Type Detected - BLOCKED**

Using `any` defeats TypeScript's type system and should be avoided.

**Instead of `any`, use:**

1. **Specific types** - Define the actual type you expect
   ```typescript
   function process(data: UserData): Result { ... }
   ```

2. **`unknown`** with type guards - When type is truly unknown
   ```typescript
   function handle(data: unknown): void {
     if (isUserData(data)) {
       // TypeScript knows data is UserData here
     }
   }
   ```

3. **Generics** - For flexible but type-safe code
   ```typescript
   function identity<T>(value: T): T { return value; }
   ```

4. **Union types** - When multiple specific types are possible
   ```typescript
   type Result = Success | Failure;
   ```

**If you must use `any`:**
- Add a `// eslint-disable-next-line @typescript-eslint/no-explicit-any` with justification
- Create a follow-up task to properly type it later
