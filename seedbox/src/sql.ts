import postgres from "postgres";

export default postgres(process.env.DATABASE_URL || "postgres://atlas@localhost/atlas");
