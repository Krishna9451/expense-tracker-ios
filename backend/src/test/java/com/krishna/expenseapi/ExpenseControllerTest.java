package com.krishna.expenseapi;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class ExpenseControllerTest {

    @Autowired
    private MockMvc mvc;

    private static final String ID = "11111111-1111-1111-1111-111111111111";
    private static final String BODY = """
        {"id":"%s","title":"Coffee","amount":120.5,"category":"Food","date":"2026-11-21T10:00:00Z"}
        """.formatted(ID);

    @Test
    void upsertThenListThenDelete() throws Exception {
        mvc.perform(put("/api/expenses/" + ID).contentType(MediaType.APPLICATION_JSON).content(BODY))
           .andExpect(status().isOk());

        mvc.perform(get("/api/expenses"))
           .andExpect(status().isOk())
           .andExpect(jsonPath("$[0].title").value("Coffee"));

        mvc.perform(delete("/api/expenses/" + ID)).andExpect(status().isNoContent());
        mvc.perform(delete("/api/expenses/" + ID)).andExpect(status().isNotFound());
    }

    @Test
    void rejectsInvalidExpense() throws Exception {
        String bad = """
            {"id":"%s","title":"","amount":-5,"category":"Food","date":"2026-11-21T10:00:00Z"}
            """.formatted(ID);
        mvc.perform(post("/api/expenses").contentType(MediaType.APPLICATION_JSON).content(bad))
           .andExpect(status().isBadRequest());
    }
}
