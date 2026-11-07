import { useQuery } from "@tanstack/react-query";
import { getJson, type Session } from "./api";
export function useSession() {
  return useQuery({
    queryKey: ["session"],
    queryFn: () => getJson<Session>("/session.json"),
    retry: false,
  });
}
