# From agenix docs: https://github.com/ryantm/agenix
let
  # user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0idNvgGiucWgup/mP78zyC23uFjYq0evcWdjGQUaBH";
  # user2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILI6jSq53F/3hEmSs+oq9L4TwOo1PrDMAgcA1uo1CCV/";
  # users = [ user1 user2 ];

  dormlab-user =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOwgUsNVmcAT7HmaNgRR0mxQVLP1yJWr5UITw7NcmBVc snowflake@dormlab";
  dormlab-root =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHD4MN8a6OsJdKQrSBhEERPQ3kerH0jE8frTbtkLoMCU";
  # system2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKzxQgondgEYcLpcPdJLrTdNgZ2gznOHCAxMdaceTUT1";
  # systems = [ system1 system2 ];
in {
  "frp-token.age".publicKeys = [ dormlab-user dormlab-root ];
  "frp-serverAddr.age".publicKeys = [ dormlab-user dormlab-root ];
  "frp-serverPort.age".publicKeys = [ dormlab-user dormlab-root ];
  # "secret2.age".publicKeys = users ++ systems;
  # "armored-secret.age" = {
  #   publicKeys = [ user1 ];
  #   armor = true;
  # };
}
