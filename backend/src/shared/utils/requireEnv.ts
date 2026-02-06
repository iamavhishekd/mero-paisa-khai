export default function requireEnv(name: string) {
  const value = process.env[name];

  if (value === undefined || value === null || value === "") {
    console.error(`❌ Missing required environment variable: ${name}`);
    process.exit(1);
  }

  return value;
}
