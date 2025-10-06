mod handlers;
mod models;

use actix_web::{web, App, HttpServer};
use handlers::{benchmark, get_users};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let num_workers = std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4);

    println!("Starting Rust API server on http://127.0.0.1:5003");
    println!("Using {} worker threads", num_workers);

    HttpServer::new(|| {
        App::new()
            .route("/users", web::get().to(get_users))
            .route("/benchmark", web::get().to(benchmark))
    })
    .workers(num_workers)
    .bind("127.0.0.1:5003")?
    .run()
    .await
}
