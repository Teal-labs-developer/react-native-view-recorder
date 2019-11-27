package com.toddle.Sketch;

import android.graphics.Path;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.util.LinkedList;

public class MyPath extends Path {

    public   LinkedList<Action> actions = new LinkedList<>();

    private void readObject(ObjectInputStream inputStream) throws IOException, ClassNotFoundException {
        inputStream.defaultReadObject();


        LinkedList<Action> copiedActions = (LinkedList<Action>) actions.clone();

        for(Action action:actions){
            action.perform(this);
        }
    }

    @Override
    public void reset() {
        actions.clear();
        super.reset();
    }

    @Override
    public void moveTo(float x, float y) {
        actions.add(new Move(x, y));
        super.moveTo(x, y);
    }

    @Override
    public void lineTo(float x, float y) {
        actions.add(new Line(x, y));
        super.lineTo(x, y);
    }

    @Override
    public void quadTo(float x1, float y1, float x2, float y2) {
        actions.add(new Quad(x1, y1, x2, y2));
        super.quadTo(x1, y1, x2, y2);
    }
}
