defprotocol DB do
  @doc "Accesses the configured databse. Supports for now MongoDB adn PostgreSQL"
  def get(struct)
  def insert(struct)
  def update(struct)
  def delete(struct)
end
