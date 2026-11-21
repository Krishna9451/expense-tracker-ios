package com.krishna.expenseapi;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "expenses")
public class Expense {

    @Id
    @NotNull
    private UUID id;

    @NotBlank
    private String title;

    @Positive
    private double amount;

    @NotBlank
    private String category;

    @NotNull
    @Column(name = "expense_date")
    private Instant date;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public double getAmount() { return amount; }
    public void setAmount(double amount) { this.amount = amount; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public Instant getDate() { return date; }
    public void setDate(Instant date) { this.date = date; }
}
