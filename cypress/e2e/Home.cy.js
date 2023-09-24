describe("Home", () => {
  beforeEach(() => {
    cy.visitApp("/");
  });

  it("Loads", () => {
    cy.contains("Reckoning");
  });
});
