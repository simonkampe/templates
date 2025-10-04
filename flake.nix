{
  description = "Opinionated Nix templates";

  outputs = { self }:
  {
    templates = {
    
      latex = {
        path = ./latex;
        description = "LaTeX template";
      };

      python = {
        path = ./python;
        description = "Python template";
      };
      
      rust = {
        path = ./rust;
        description = "Rust template using Oxalicas overlay";
      };
    
      tauri = {
        path = ./rust-tauri;
        description = "Rust template for Tauri projects";
      };
    };
  };
}
