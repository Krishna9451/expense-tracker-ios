package com.krishna.expenseapi;

import jakarta.validation.Valid;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/expenses")
public class ExpenseController {

    private final ExpenseRepository repository;

    public ExpenseController(ExpenseRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<Expense> list() {
        return repository.findAll(Sort.by(Sort.Direction.DESC, "date"));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Expense create(@Valid @RequestBody Expense expense) {
        return repository.save(expense);
    }

    /** Create-or-update. The iOS client uses this so repeated syncs are idempotent. */
    @PutMapping("/{id}")
    public Expense upsert(@PathVariable UUID id, @Valid @RequestBody Expense expense) {
        expense.setId(id);
        return repository.save(expense);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        if (!repository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Expense not found");
        }
        repository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
